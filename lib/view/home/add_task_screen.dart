import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/core/db_helper.dart';
import 'package:to_do_app/core/sync_service.dart';
import 'package:to_do_app/core/theme_app.dart';
import 'package:to_do_app/model/category_model.dart';
import 'package:to_do_app/model/task_model.dart';
import 'package:to_do_app/view/home/add_category_screen.dart';
import 'package:to_do_app/widget/app_snackbar.dart';
import 'package:to_do_app/widget/build_textfield.dart';
import 'package:to_do_app/widget/category_item.dart';
import 'package:to_do_app/widget/primary_button.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, this.task});
  final Task? task;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  DateTime? selectedDate;
  bool isEditing = false;
  List<Category> categories = [];
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchCategories();
    setState(() {});
    if (widget.task != null) {
      isEditing = true;
      taskNameController.text = widget.task!.title;
      descriptionController.text = widget.task!.description;
      selectedDate = widget.task!.dueDate;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      categories = List<Category>.from(await DBHelper.getCategories(user.uid));
      if (categories.isEmpty) {
        categories.add(Category(id: -1, name: "All", isSelected: true));
      } else {
        // If editing, select the category of the task
        if (isEditing && widget.task?.categoryId != null) {
          bool found = false;
          for (var c in categories) {
            if (c.id == widget.task!.categoryId) {
              c.isSelected = true;
              found = true;
            } else {
              c.isSelected = false;
            }
          }
          if (!found) {
            categories[0].isSelected = true;
          }
        } else {
          categories[0].isSelected = true;
        }
      }
      setState(() {});
    } catch (e) {
      AppSnackbar.error("Failed to fetch categories: $e");
    }
  }

  Future<void> saveTask() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (taskNameController.text.trim().isEmpty) {
      AppSnackbar.error("Task name cannot be empty");
      return;
    }
    if (selectedDate == null) {
      AppSnackbar.error("Please select a due date");
      return;
    }

    final selectedCategory = categories.firstWhere(
      (c) => c.isSelected,
      orElse: () => Category(id: -1, name: "All"),
    );

    Task newTask = Task(
      id: widget.task?.id,
      title: taskNameController.text.trim(),
      description: descriptionController.text.trim(),
      dueDate: selectedDate!,
      categoryId: selectedCategory.id != -1 ? selectedCategory.id : null,
      isCompleted: widget.task?.isCompleted ?? false,
      isFavorite: widget.task?.isFavorite ?? false,
      userId: user.uid,
    );

    try {
      // Save to local database first
      debugPrint("Starting task save...");

      if (isEditing) {
        await DBHelper.updateTask(newTask);
        debugPrint("Task updated in DB");
      } else {
        await DBHelper.insertTask(newTask);
        debugPrint("Task inserted in DB");
      }

      // Trigger background sync
      SyncService().sync();
      Get.back(result: true);

      AppSnackbar.success(
        isEditing ? "Task updated successfully" : "Task added successfully",
      );
      debugPrint("Showing success message");
      debugPrint("Calling Get.back()");
    } catch (e) {
      AppSnackbar.error("Failed to save task: $e");
      debugPrint("Error saving task: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: TextButton(
          onPressed: () async {
            Get.back();
          },
          child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
        ),
        actions: [
          DropdownButton(
            dropdownColor: Colors.white.withValues(alpha: .1),
            items: const [
              DropdownMenuItem(
                value: 'add category',
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Add Category', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            elevation: 0,
            underline: Container(),
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).primaryIconTheme.color,
            ),
            onChanged: (itemIdntefier) async {
              if (itemIdntefier == 'add category') {
                debugPrint("add category");
                await Get.to(() => AddCategoryScreen());
                await fetchCategories();
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? "Edit Task" : "Add New Task",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 53),

                BuildTextFormField(
                  text: isEditing ? "Edit Task" : "New Task",
                  hintText: "Task Name",
                  controller: taskNameController,
                ),
                BuildTextFormField(
                  text: isEditing ? "Edit Description" : "Description",
                  hintText: "Enter Description",
                  controller: descriptionController,
                ),
                Text(
                  "Due Date",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8),

                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      builder: (context, child) {
                        return child!;
                      },
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFF979797)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: selectedDate == null
                              ? Colors.white
                              : ThemeApp.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate == null
                              ? (isEditing ? 'No Date Chosen' : 'Set Due Date')
                              : DateFormat('MMM d, yyyy').format(selectedDate!),
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "No categories found",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: (categories).map((category) {
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

                SizedBox(height: 24),

                primaryButton(
                  context: context,
                  text: isEditing ? "Edit Task" : "Add Task",
                  onTap: saveTask,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
