import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:to_do_app/core/db_helper.dart';
import 'package:to_do_app/model/category_model.dart';
import 'package:to_do_app/model/task_model.dart';
import 'package:to_do_app/view/home/add_task_screen.dart';
import 'package:to_do_app/widget/app_snackbar.dart';
import 'package:to_do_app/core/sync_service.dart';
import 'package:to_do_app/widget/category_item.dart';
import 'package:to_do_app/widget/empty_task_widget.dart';
import 'package:to_do_app/widget/task_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> categories = [];
  List<Task> tasks = [];
  bool isTaskIncomplete = true;
  bool isLoading = true;
  String searchQuery = "";
  final TextEditingController searchController = TextEditingController();

  Future<void> loadData() async {
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1️⃣ Fetch Categories from SQLite
      final dbCategories = await DBHelper.getCategories(user.uid);
      tasks = await DBHelper.getTasks(user.uid);

      // Always add "All" at the beginning
      categories = [
        Category(id: -1, name: "All", isSelected: true),
        ...dbCategories,
      ];

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      AppSnackbar.error("Failed to load data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (categories.isEmpty) {
      // لا توجد أي كاتيجوري
      return const Scaffold(
        body: Center(
          child: Text(
            "No categories found",
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.black,
      );
    }

    // Ensure at least one category exists and is selected
    final selectedCategory = categories.firstWhere(
      (c) => c.isSelected,
      orElse: () => categories[0],
    );

    final filteredIncompleteTasks = tasks.where(
      (task) =>
          !task.isCompleted &&
          (selectedCategory.id == -1 ||
              task.categoryId == selectedCategory.id) &&
          (task.title.toLowerCase().contains(searchQuery) ||
              task.description.toLowerCase().contains(searchQuery)),
    );

    final filteredCompletedTasks = tasks.where(
      (task) =>
          task.isCompleted &&
          (selectedCategory.id == -1 ||
              task.categoryId == selectedCategory.id) &&
          (task.title.toLowerCase().contains(searchQuery) ||
              task.description.toLowerCase().contains(searchQuery)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Todo List",
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
      body: tasks.isEmpty
          ? const EmptyTaskWidget(
              title: "What do you want to do today?",
              desc: "Tap + to add your tasks",
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search by title...",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  searchController.clear();
                                  searchQuery = "";
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories.map((category) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            for (var c in categories) {
                              c.isSelected = false;
                            }
                            category.isSelected = true;
                          });
                        },
                        child: CategoryItem(
                          category: category,
                          isSelected: category.isSelected,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isTaskIncomplete = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: isTaskIncomplete
                                ? Border.all(color: Colors.white, width: 1)
                                : null,
                          ),
                          child: Text(
                            "Tasks Incomplete",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isTaskIncomplete = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: !isTaskIncomplete
                                ? Border.all(color: Colors.white, width: 1)
                                : null,
                          ),
                          child: Text(
                            "Tasks Complete",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isTaskIncomplete)
                    filteredIncompleteTasks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            child: Text(
                              searchQuery.isEmpty
                                  ? "No Incomplete Tasks"
                                  : "No results matching \"$searchQuery\"",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : Column(
                            children: filteredIncompleteTasks.map((task) {
                              return TaskItem(
                                context: context,
                                onFavorite: () async {
                                  setState(() {
                                    task.isFavorite = !task.isFavorite;
                                    task.isSynced = false;
                                  });
                                  await DBHelper.updateTask(task);
                                  SyncService().sync();
                                },
                                key_: ValueKey(task.id),
                                task: task,
                                onChanged: (value) async {
                                  setState(() {
                                    task.isCompleted = value!;
                                    task.isSynced = false;
                                  });
                                  await DBHelper.updateTask(task);
                                  SyncService().sync();
                                },
                                onDismissed: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    await DBHelper.deleteTask(task.id!);
                                    SyncService().sync();
                                    setState(() {
                                      tasks.remove(task);
                                    });
                                    AppSnackbar.success("Task deleted");
                                  }
                                },
                              );
                            }).toList(),
                          )
                  else
                    filteredCompletedTasks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            child: Text(
                              searchQuery.isEmpty
                                  ? "No Completed Tasks"
                                  : "No results matching \"$searchQuery\"",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : Column(
                            children: filteredCompletedTasks.map((task) {
                              return TaskItem(
                                context: context,
                                onFavorite: () async {
                                  setState(() {
                                    task.isFavorite = !task.isFavorite;
                                    task.isSynced = false;
                                  });
                                  await DBHelper.updateTask(task);
                                  SyncService().sync();
                                },
                                key_: ValueKey(task.id),
                                task: task,
                                onChanged: (value) async {
                                  setState(() {
                                    task.isCompleted = value!;
                                    task.isSynced = false;
                                  });
                                  await DBHelper.updateTask(task);
                                  SyncService().sync();
                                },
                                onDismissed: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    await DBHelper.deleteTask(task.id!);
                                    SyncService().sync();
                                    setState(() {
                                      tasks.remove(task);
                                    });
                                    AppSnackbar.success("Task deleted");
                                  }
                                },
                              );
                            }).toList(),
                          ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Get.to(() => const AddTaskScreen());
          await loadData();
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
