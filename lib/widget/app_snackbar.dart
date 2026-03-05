import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  static void error(String message) {
    Get.snackbar(
      "Error",
      message,
      backgroundColor: const Color(0xFF1C1C1C),
      colorText: const Color.fromRGBO(255, 255, 255, 1),
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error, color: Colors.red),
    );
  }

  static void success(String message) {
    Get.snackbar(
      "Success",
      message,
      backgroundColor: const Color(0xFF1C1C1C),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }
}
