import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/theme_app.dart';
import 'package:to_do_app/view/auth/signup_screen.dart';
import 'package:to_do_app/view/home/main_screen.dart';
import 'package:to_do_app/widget/app_snackbar.dart';
import 'package:to_do_app/widget/build_textfield.dart';
import 'package:to_do_app/widget/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    SharedPreferences prefs;

    Future<void> signIn() async {
      isLoading = true;
      setState(() {});
      try {
        if (emailController.text.trim().isEmpty ||
            passwordController.text.trim().isEmpty ||
            passwordController.text.trim().length < 6) {
          AppSnackbar.error("Please enter valid credentials");
          setState(() => isLoading = false);
          return;
        }
        prefs = await SharedPreferences.getInstance();
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );
        setState(() => isLoading = false);
        // Navigate to home screen
        Get.offAll(() => const MainScreen());
        prefs.setString('userId', credential.user!.uid);
        prefs.setString('email', credential.user!.email ?? '');

        prefs.setBool('isLoggedIn', true);
        AppSnackbar.success("Login successful");
      } on FirebaseAuthException catch (e) {
        AppSnackbar.error("Failed to sign in: ${e.message}");
        if (e.code == 'user-not-found') {
        } else if (e.code == 'wrong-password') {
          AppSnackbar.error("Wrong password provided for that user.");
        }
        setState(() => isLoading = false);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: TextButton(
          onPressed: () async {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
        ),
      ),

      body: SingleChildScrollView(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Login ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 53),
                    BuildTextFormField(
                      text: "Email",
                      hintText: "Enter Email",
                      keyboardType: TextInputType.emailAddress,
                      controller: emailController,
                    ),
                    BuildTextFormField(
                      text: "Password",
                      hintText: "Enter Password",
                      controller: passwordController,
                      obscureText: true,
                    ),
                    SizedBox(height: 25),
                    primaryButton(
                      context: context,
                      text: "Login",
                      onTap: signIn,
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(height: 24),

                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .67),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),

                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: ThemeApp.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Navigate to Sign Up screen
                                  Get.to(() => const SignupScreen());
                                },
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Align(
                alignment: Alignment.center,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
