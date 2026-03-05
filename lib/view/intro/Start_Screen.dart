import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:to_do_app/core/theme_app.dart';
import 'package:to_do_app/view/auth/login_screen.dart';
import 'package:to_do_app/view/auth/signup_screen.dart';
import 'package:to_do_app/widget/primary_button.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 59),

            Text(
              'Welcome to UpTodo',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                fontFamily: "Lato",
                color: Colors.white,
              ),
            ),
            SizedBox(height: 38),

            Text(
              'Please login to your account or create \n new account to continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: "Lato",
                color: Colors.white.withValues(alpha: .67),
              ),
            ),
            SizedBox(height: 370),

            primaryButton(
              context: context,
              text: "LOGIN",
              onTap: () {
                Get.to(() => const LoginScreen());
              },
            ),
            SizedBox(height: 28),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              margin: EdgeInsets.only(bottom: 20),
              height: 50,
              width: double.infinity,

              child: OutlinedButton(
                onPressed: () {
                  Get.to(() => const SignupScreen());
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ThemeApp.primaryColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(4),
                  ),
                ),
                child: Text(
                  "Create account",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
