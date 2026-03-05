import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/core/db_helper.dart';
import 'package:to_do_app/model/task_model.dart';
import 'package:to_do_app/widget/app_snackbar.dart';
import 'package:to_do_app/widget/empty_task_widget.dart';
import 'package:to_do_app/widget/task_item.dart';

class FavTaskScreen extends StatefulWidget {
  const FavTaskScreen({super.key});

  @override
  State<FavTaskScreen> createState() => _FavTaskScreenState();
}

class _FavTaskScreenState extends State<FavTaskScreen> {
  List<Task> favoriteTasks = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadFavoriteTasks();
  }

  Future<void> updateTaskInFirestore(Task task) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      // Find the task in Firestore by matching fields
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('tasks')
          .where('title', isEqualTo: task.title)
          .where('dueDate', isEqualTo: task.dueDate.toIso8601String())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'isFavorite': task.isFavorite ? 1 : 0,
          'isCompleted': task.isCompleted ? 1 : 0,
        });
      }
    } catch (e) {
      debugPrint("Firestore update failed: $e");
      // Don't show error to user, just log it
    }
  }

  Future<void> loadFavoriteTasks() async {
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch all tasks from SQLite
      final allTasks = await DBHelper.getTasks(user.uid);

      // Filter only favorite tasks
      favoriteTasks = allTasks
          .where((task) => task.isFavorite == true)
          .toList();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      AppSnackbar.error("Failed to load favorite tasks: $e");
      debugPrint("Error loading favorites: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        backgroundColor: Colors.black,
      );
    }

    // Split tasks into incomplete and completed
    final incompleteFavoriteTasks = favoriteTasks.where(
      (task) => !task.isCompleted,
    );
    final completedFavoriteTasks = favoriteTasks.where(
      (task) => task.isCompleted,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Important Tasks",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: favoriteTasks.isEmpty
          ? const EmptyTaskWidget(title: "No Favorite Tasks", desc: "")
          : RefreshIndicator(
              onRefresh: loadFavoriteTasks,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Favorite Tasks Progress",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (incompleteFavoriteTasks.isEmpty)
                      const Text(
                        "No Incomplete Favorite Tasks",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ...incompleteFavoriteTasks.map((task) {
                      return TaskItem(
                        context: context,
                        onFavorite: () async {
                          setState(() {
                            task.isFavorite = !task.isFavorite;
                          });
                          await DBHelper.updateTask(task);
                          await updateTaskInFirestore(task);
                          await loadFavoriteTasks(); // Reload to update the list
                        },
                        key_: ValueKey(task.id),
                        task: task,
                        onChanged: (value) async {
                          setState(() {
                            task.isCompleted = value!;
                          });
                          await DBHelper.updateTask(task);
                          await updateTaskInFirestore(task);
                          await loadFavoriteTasks(); // Reload to update sections
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                    const Text(
                      "Favorite Tasks Completed",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (completedFavoriteTasks.isEmpty)
                      const Text(
                        "No Completed Favorite Tasks",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ...completedFavoriteTasks.map((task) {
                      return TaskItem(
                        context: context,
                        onFavorite: () async {
                          setState(() {
                            task.isFavorite = !task.isFavorite;
                          });
                          await DBHelper.updateTask(task);
                          await updateTaskInFirestore(task);
                          await loadFavoriteTasks(); // Reload to update the list
                        },
                        key_: ValueKey(task.id),
                        task: task,
                        onChanged: (value) async {
                          setState(() {
                            task.isCompleted = value!;
                          });
                          await DBHelper.updateTask(task);
                          await updateTaskInFirestore(task);
                          await loadFavoriteTasks(); // Reload to update sections
                        },
                        onDismissed: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            // Delete from SQLite
                            await DBHelper.deleteTask(task.id!);

                            // Delete from Firestore
                            if (FirebaseAuth.instance.currentUser != null) {
                              try {
                                final snapshot = await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('tasks')
                                    .where('title', isEqualTo: task.title)
                                    .where(
                                      'dueDate',
                                      isEqualTo: task.dueDate.toIso8601String(),
                                    )
                                    .limit(1)
                                    .get();

                                if (snapshot.docs.isNotEmpty) {
                                  await snapshot.docs.first.reference.delete();
                                }
                              } catch (e) {
                                debugPrint("Firestore delete failed: $e");
                              }
                            }

                            setState(() {
                              favoriteTasks.remove(task);
                            });
                            AppSnackbar.success("Task deleted");
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}
