import 'package:flutter/material.dart';
import 'package:to_do_app/model/category_model.dart';

class CategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  const CategoryItem({
    super.key,
    required this.category,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: .1)
            : Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: Colors.white) : null,
      ),
      child: Text(
        category.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: Colors.white,
        ),
      ),
    );
  }
}
