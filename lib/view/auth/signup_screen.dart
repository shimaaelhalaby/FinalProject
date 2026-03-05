import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/theme_app.dart';
import 'package:to_do_app/view/auth/login_screen.dart';
import 'package:to_do_app/view/home/main_screen.dart';
import 'package:to_do_app/widget/app_snackbar.dart';
import 'package:to_do_app/widget/build_textfield.dart';
import 'package:to_do_app/widget/primary_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController nameController = TextEditingController();
    SharedPreferences prefs;

    Future<void> signUp() async {
      isLoading = true;

      if (emailController.text.isEmpty ||
          passwordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        AppSnackbar.error("Please fill all the fields.");
        return;
      }
      if (passwordController.text.length < 6) {
        AppSnackbar.error("Password must be at least 6 characters.");
        return;
      }
      if (passwordController.text != confirmPasswordController.text) {
        AppSnackbar.error("Passwords do not match.");
        return;
      }
      try {
        prefs = await SharedPreferences.getInstance();
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );
        isLoading = false;
        // Navigate to home screen

        Get.offAll(() => const MainScreen());
        prefs.setString('userId', credential.user!.uid);
        prefs.setString('email', credential.user!.email ?? '');
        prefs.setString('name', nameController.text);
        prefs.setBool('isLoggedIn', true);
        AppSnackbar.success("Account created successfully");
      } on FirebaseAuthException catch (e) {
        isLoading = false;
        if (e.code == 'weak-password') {
          AppSnackbar.error("The password provided is too weak.");
        } else if (e.code == 'email-already-in-use') {
          AppSnackbar.error("The account already exists for that email.");
        }
      } catch (e) {
        isLoading = false;
        Get.snackbar("Error", "Failed to sign up: ${e.toString()}");
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
            if (isLoading) Align(alignment: Alignment.center, child: Center(child: CircularProgressIndicator())),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Register ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 53),
                    BuildTextFormField(
                      text: "Name",
                      hintText: "Enter Name",
                      controller: nameController,
                      keyboardType: TextInputType.text,
                    ),
                    BuildTextFormField(
                      text: "Email",
                      hintText: "Enter Email",
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    BuildTextFormField(
                      text: "Password",
                      hintText: "Enter Password",
                      controller: passwordController,
                      obscureText: true,
                    ),
                    BuildTextFormField(
                      text: "Confirm Password",
                      hintText: "Enter Confirm Password",
                      controller: confirmPasswordController,
                      obscureText: true,
                    ),

                    SizedBox(height: 25),
                    primaryButton(
                      context: context,
                      text: "Register",
                      onTap: () {
                        signUp();
                      },
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Already have an account?  ",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .67),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                color: ThemeApp.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Navigate to Sign Up screen
                                  Get.to(() => const LoginScreen());
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
          ],
        ),
      ),
    );
  }
}
