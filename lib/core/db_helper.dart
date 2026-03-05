import 'package:flutter/foundation.dart' hide Category;
import 'package:sqflite/sqflite.dart';
import 'package:to_do_app/model/category_model.dart';
import 'package:path/path.dart';
import 'package:to_do_app/model/task_model.dart';
import 'package:to_do_app/model/user_model.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> getDb() async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  static Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'to_do_app.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            isSelected INTEGER,
            firestoreId TEXT,
            isSynced INTEGER DEFAULT 0,
            isDeleted INTEGER DEFAULT 0,
            userId TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            dueDate TEXT,
            isCompleted INTEGER,
            isFavorite INTEGER,
            categoryId INTEGER,
            isSynced INTEGER DEFAULT 0,
            firestoreId TEXT,
            isDeleted INTEGER DEFAULT 0,
            userId TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT,
            imagePath TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute(
              'ALTER TABLE tasks ADD COLUMN isSynced INTEGER DEFAULT 0',
            );
          } catch (e) {
            debugPrint("Error adding isSynced column: $e");
          }
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users(
              id TEXT PRIMARY KEY,
              name TEXT,
              email TEXT,
              imagePath TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          try {
            // Upgrade categories
            await db.execute(
              'ALTER TABLE categories ADD COLUMN firestoreId TEXT',
            );
            await db.execute(
              'ALTER TABLE categories ADD COLUMN isSynced INTEGER DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE categories ADD COLUMN isDeleted INTEGER DEFAULT 0',
            );

            // Upgrade tasks
            await db.execute('ALTER TABLE tasks ADD COLUMN firestoreId TEXT');
            await db.execute(
              'ALTER TABLE tasks ADD COLUMN isDeleted INTEGER DEFAULT 0',
            );
          } catch (e) {
            debugPrint("Error in migration to v3: $e");
          }
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE categories ADD COLUMN userId TEXT');
            await db.execute('ALTER TABLE tasks ADD COLUMN userId TEXT');
          } catch (e) {
            debugPrint("Error in migration to v4: $e");
          }
        }
      },
    );
  }

  // ----------------- User -----------------
  static Future<void> saveUser(UserModel user) async {
    final db = await getDb();
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<UserModel?> getUser(String id) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  // ----------------- Tasks -----------------
  static Future<int> insertTask(Task task) async {
    final db = await getDb();
    return await db.insert('tasks', task.toMap());
  }

  static Future<int> updateTask(Task task) async {
    final db = await getDb();
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static Future<int> deleteTask(int id) async {
    final db = await getDb();
    return await db.update(
      'tasks',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Task>> getTasks(String userId) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'isDeleted = ? AND userId = ?',
      whereArgs: [0, userId],
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  static Future<List<Task>> getUnsyncedTasks(String userId) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'isSynced = ? AND userId = ?',
      whereArgs: [0, userId],
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  static Future<List<Task>> getDeletedTasks(String userId) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'isDeleted = ? AND firestoreId IS NOT NULL AND userId = ?',
      whereArgs: [1, userId],
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  static Future<void> removeTaskLocally(int id) async {
    final db = await getDb();
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Task?> getTaskByFirestoreId(
    String firestoreId,
    String userId,
  ) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'firestoreId = ? AND userId = ?',
      whereArgs: [firestoreId, userId],
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  static Future<Task?> getTaskByTitle(
    String title,
    String dueDate,
    String userId,
  ) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'title = ? AND dueDate = ? AND userId = ? AND isDeleted = 0',
      whereArgs: [title, dueDate, userId],
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  // ----------------- Categories -----------------
  static Future<int> deleteCategory(int id) async {
    final db = await getDb();
    return await db.update(
      'categories',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> insertCategory(Category category) async {
    final db = await getDb();
    return await db.insert('categories', category.toMap());
  }

  static Future<int> updateCategory(Category category) async {
    final db = await getDb();
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  static Future<List<Category>> getCategories(String userId) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'isDeleted = ? AND userId = ?',
      whereArgs: [0, userId],
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  static Future<List<Category>> getUnsyncedCategories(String userId) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'isSynced = ? AND userId = ?',
      whereArgs: [0, userId],
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  static Future<Category?> getCategoryByFirestoreId(
    String firestoreId,
    String userId,
  ) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'firestoreId = ? AND userId = ?',
      whereArgs: [firestoreId, userId],
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  static Future<Category?> getCategoryByName(String name, String userId) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'name = ? AND userId = ? AND isDeleted = 0',
      whereArgs: [name, userId],
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  static Future<List<Category>> getDeletedCategories(String userId) async {
    final db = await getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'isDeleted = ? AND firestoreId IS NOT NULL AND userId = ?',
      whereArgs: [1, userId],
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  static Future<void> removeCategoryLocally(int id) async {
    final db = await getDb();
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAllData() async {
    final db = await getDb();
    await db.delete('tasks');
    await db.delete('categories');
    await db.delete('users');
  }
}
