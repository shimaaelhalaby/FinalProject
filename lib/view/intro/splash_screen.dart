import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/view/home/main_screen.dart';
import 'package:to_do_app/view/intro/onboarding_screen.dart';
import 'package:to_do_app/view/intro/Start_Screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SharedPreferences? sharedPreferences;
  Future<void> load() async {
    sharedPreferences = await SharedPreferences.getInstance();
    await Future.delayed(Duration(seconds: 3)).then((value) {
      if (sharedPreferences!.getBool("isFirstTime") == null ||
          sharedPreferences!.getBool("isFirstTime") == false) {
        Get.offAll(() => const OnboardingScreen(), transition: Transition.fade);
      } else if (sharedPreferences!.getBool("isLoggedIn") == null ||
          sharedPreferences!.getBool("isLoggedIn") == false) {
        Get.offAll(() => const StartScreen(), transition: Transition.fade);
      } else {
        Get.offAll(() => const MainScreen(), transition: Transition.fade);
      }
    });
  }

  @override
  void initState() {
    load();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png'),

            SizedBox(height: 20),

            Text(
              'UpTodo',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                fontFamily: "Lato",
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
