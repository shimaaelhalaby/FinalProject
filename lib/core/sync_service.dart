import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:to_do_app/core/db_helper.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:to_do_app/model/category_model.dart';
import 'package:to_do_app/model/task_model.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  StreamSubscription? _tasksSubscription;
  StreamSubscription? _categoriesSubscription;

  void init() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        sync();
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        sync();
        _setupRealtimeListeners(user.uid);
      } else {
        _cancelListeners();
      }
    });
  }

  void _setupRealtimeListeners(String userId) {
    _cancelListeners();

    _tasksSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots()
        .listen((snapshot) {
          _pullTasks(snapshot.docs, userId);
        });

    _categoriesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots()
        .listen((snapshot) {
          _pullCategories(snapshot.docs, userId);
        });
  }

  void _cancelListeners() {
    _tasksSubscription?.cancel();
    _categoriesSubscription?.cancel();
  }

  Future<void> sync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _syncCategories(user.uid);
      await _syncTasks(user.uid);
      debugPrint("Full sync complete");
    } catch (e) {
      debugPrint("Sync failed: $e");
    }
  }

  // ----------------- Categories Sync -----------------

  Future<void> _syncCategories(String userId) async {
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('categories');

    // 1. Push deletions
    final deleted = await DBHelper.getDeletedCategories(userId);
    for (var cat in deleted) {
      if (cat.firestoreId != null) {
        await collection.doc(cat.firestoreId).delete();
      }
      await DBHelper.removeCategoryLocally(cat.id!);
    }

    // 2. Push unsynced changes
    final unsynced = await DBHelper.getUnsyncedCategories(userId);
    for (var cat in unsynced) {
      if (cat.firestoreId == null) {
        // Create new
        final doc = await collection.add({
          'name': cat.name,
          'isSelected': cat.isSelected,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        cat.firestoreId = doc.id;
      } else {
        // Update existing
        await collection.doc(cat.firestoreId).update({
          'name': cat.name,
          'isSelected': cat.isSelected,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      cat.isSynced = true;
      await DBHelper.updateCategory(cat);
    }
  }

  Future<void> _pullCategories(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String userId,
  ) async {
    for (var doc in docs) {
      final data = doc.data();
      final firestoreId = doc.id;
      final name = data['name'] ?? '';

      // 1. Try to find by firestoreId
      var local = await DBHelper.getCategoryByFirestoreId(firestoreId, userId);

      // 2. If not found by firestoreId, try by name (race condition check)
      if (local == null) {
        local = await DBHelper.getCategoryByName(name, userId);
      }

      if (local == null) {
        // 3. Still not found, insert new
        await DBHelper.insertCategory(
          Category(
            name: name,
            isSelected: data['isSelected'] ?? false,
            firestoreId: firestoreId,
            isSynced: true,
            userId: userId,
          ),
        );
      } else {
        // 4. Found local record, update it with firestoreId and other fields
        local.name = name;
        local.isSelected = data['isSelected'] ?? local.isSelected;
        local.firestoreId = firestoreId; // Ensure firestoreId is set
        local.isSynced = true;
        await DBHelper.updateCategory(local);
      }
    }
  }

  // ----------------- Tasks Sync -----------------

  Future<void> _syncTasks(String userId) async {
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks');

    // 1. Push deletions
    final deleted = await DBHelper.getDeletedTasks(userId);
    for (var task in deleted) {
      if (task.firestoreId != null) {
        await collection.doc(task.firestoreId).delete();
      }
      await DBHelper.removeTaskLocally(task.id!);
    }

    // 2. Push unsynced changes
    final unsynced = await DBHelper.getUnsyncedTasks(userId);
    for (var task in unsynced) {
      // Map local categoryId to firestoreId if available
      String? categoryFirestoreId;
      if (task.categoryId != null) {
        final category = (await DBHelper.getCategories(
          userId,
        )).where((c) => c.id == task.categoryId).firstOrNull;
        categoryFirestoreId = category?.firestoreId;
      }

      final taskData = {
        'title': task.title,
        'description': task.description,
        'dueDate': task.dueDate.toIso8601String(),
        'isCompleted': task.isCompleted,
        'isFavorite': task.isFavorite,
        'categoryId': categoryFirestoreId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (task.firestoreId == null) {
        final doc = await collection.add(taskData);
        task.firestoreId = doc.id;
      } else {
        await collection.doc(task.firestoreId).update(taskData);
      }
      task.isSynced = true;
      await DBHelper.updateTask(task);
    }
  }

  Future<void> _pullTasks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String userId,
  ) async {
    for (var doc in docs) {
      final data = doc.data();
      final firestoreId = doc.id;
      final title = data['title'] ?? '';
      final dueDateStr = data['dueDate'] ?? '';

      // 1. Try to find by firestoreId
      var local = await DBHelper.getTaskByFirestoreId(firestoreId, userId);

      // 2. If not found by firestoreId, try by title and dueDate (race condition check)
      if (local == null) {
        local = await DBHelper.getTaskByTitle(title, dueDateStr, userId);
      }

      // Resolve categoryId from firestoreId
      int? localCategoryId;
      if (data['categoryId'] != null) {
        final cat = await DBHelper.getCategoryByFirestoreId(
          data['categoryId'],
          userId,
        );
        localCategoryId = cat?.id;
      }

      if (local == null) {
        // 3. Still not found, insert new
        await DBHelper.insertTask(
          Task(
            title: title,
            description: data['description'] ?? '',
            dueDate: DateTime.tryParse(dueDateStr) ?? DateTime.now(),
            isCompleted: data['isCompleted'] ?? false,
            isFavorite: data['isFavorite'] ?? false,
            categoryId: localCategoryId,
            firestoreId: firestoreId,
            isSynced: true,
            userId: userId,
          ),
        );
      } else {
        // 4. Found local record, update it
        local.title = title;
        local.description = data['description'] ?? local.description;
        local.dueDate = DateTime.tryParse(dueDateStr) ?? local.dueDate;
        local.isCompleted = data['isCompleted'] ?? local.isCompleted;
        local.isFavorite = data['isFavorite'] ?? local.isFavorite;
        local.categoryId = localCategoryId;
        local.firestoreId = firestoreId; // Ensure firestoreId is set
        local.isSynced = true;
        await DBHelper.updateTask(local);
      }
    }
  }
}
