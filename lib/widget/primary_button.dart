import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme_app.dart';

Container primaryButton({required BuildContext context, text, onTap, padding}) {
  return Container(
    height: 50,
    width: double.infinity,
    padding: padding ?? EdgeInsets.symmetric(horizontal: 20),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeApp.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
    ),
  );
}
