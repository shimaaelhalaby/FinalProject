import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:to_do_app/core/db_helper.dart';
import 'package:to_do_app/model/task_model.dart';
import 'package:to_do_app/view/home/add_task_screen.dart';

class TaskItem extends StatefulWidget {
  const TaskItem({
    super.key,
    required this.context,
    required this.key_,
    required this.task,
    required this.onChanged,
    required this.onFavorite,
    this.onDismissed,
  });

  final BuildContext context;
  final Key key_;
  final Task task;
  final Function(bool?) onChanged;
  final VoidCallback? onFavorite;
  final Function(DismissDirection)? onDismissed;

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: widget.key_,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await DBHelper.deleteTask(widget.task.id!);
          return true; // Return true to dismiss the item
        } else if (direction == DismissDirection.startToEnd) {
          // Perform edit action
          Get.to(() => AddTaskScreen(task: widget.task));
          return false; // Return false to prevent dismissal
        }
        return false;
      },
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.white.withValues(alpha: .04),
          //     blurRadius: 10,
          //     offset: const Offset(0, 5),
          //   ),
          // ],
        ),
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: 16),
            const Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: .04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          children: [
            SizedBox(width: 16),
            const Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Edit",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      onDismissed: widget.onDismissed,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.white.withValues(alpha: .04),
          //     blurRadius: 10,
          //     offset: const Offset(0, 5),
          //   ),
          // ],
        ),
        child: ListTile(
          leading: Checkbox(
            shape: CircleBorder(),
            side: BorderSide(color: Colors.white, width: 2),
            value: widget.task.isCompleted,
            onChanged: (value) {
              widget.onChanged(value);
            },
          ),
          trailing: IconButton(
            onPressed: widget.onFavorite,
            icon: widget.task.isFavorite == true
                ? Icon(Icons.favorite, color: Colors.white, size: 20)
                : Icon(Icons.favorite_border, color: Colors.white, size: 20),
          ),
          title: Text(
            widget.task.title,

            style: TextStyle(
              decoration: widget.task.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: widget.task.isCompleted
                  ? Colors.white.withValues(alpha: .5)
                  : Colors.white,
              fontSize: widget.task.isCompleted ? 16 : 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withValues(alpha: .5),
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                widget.task.dueDate.toString(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .5),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
