import 'package:flutter/material.dart';

class BuildTextFormField extends StatelessWidget {
  const BuildTextFormField({
    super.key,
    required this.text,
    required this.hintText,
    this.keyboardType,
    this.obscureText,
    this.controller,
    this.icon,
  });

  final String text;
  final String hintText;
  final TextInputType? keyboardType;
  final bool? obscureText;
  final TextEditingController? controller;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            obscureText: obscureText ?? false,
            keyboardType: keyboardType ?? TextInputType.text,
            controller: controller,
            style: TextStyle(color: Colors.white, fontSize: 16),

            decoration: InputDecoration(
              suffixIcon: icon,
              hintText: hintText,
              hintStyle: TextStyle(color: Color(0XFF535353), fontSize: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
