import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/theme_app.dart';
import 'package:to_do_app/model/onboarding_model.dart';
import 'package:to_do_app/view/intro/Start_Screen.dart';
import 'package:to_do_app/widget/onboarding_item.dart';
import 'package:to_do_app/widget/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController controller = PageController(initialPage: 0);
  SharedPreferences? sharedPreferences;
  int currentIndex = 0;
  List<OnboardingModel> itmes = [
    OnboardingModel(
      image: 'assets/images/Onboading1.png',
      title: 'Manage your tasks',
      desc: 'You can easily manage all of your daily \n tasks in DoMe for free',
    ),
    OnboardingModel(
      image: 'assets/images/Onboading1.png',
      title: 'Create daily routine',
      desc:
          'In Uptodo  you can create your\n personalized routine to stay productive',
    ),
    OnboardingModel(
      image: 'assets/images/Onboading1.png',
      title: 'Orgonaize your tasks',
      desc:
          'You can organize your daily tasks \n by adding your tasks into separate categories',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: TextButton(
          onPressed: () async {
            sharedPreferences = await SharedPreferences.getInstance();
            sharedPreferences!.setBool("isFirstTime", true);

            Get.offAll(() => const StartScreen());
          },
          child: Text(
            "Skip",
            style: TextStyle(
              color: Colors.white.withValues(alpha: .44),
              fontSize: 16,
            ),
          ),
        ),
      ),
      body: Center(
        child:
            //
            PageView.builder(
              itemCount: itmes.length,
              controller: controller,
              onPageChanged: (value) => setState(() => currentIndex = value),
              itemBuilder: (context, index) {
                debugPrint("INDEX :$index");
                return onboardingItem(
                  controller: controller,
                  model: itmes[index],
                );
              },
            ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextButton(
                  onPressed: () {
                    controller.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeApp.blackColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    "Back",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .44),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: primaryButton(
                context: context,
                text: currentIndex == itmes.length - 1 ? "Get Started" : "Next",
                onTap: () async {
                  sharedPreferences = await SharedPreferences.getInstance();
                  if (currentIndex == itmes.length - 1) {
                    sharedPreferences!.setBool("isFirstTime", true);
                    Get.offAll(() => const StartScreen());
                  } else {
                    controller.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
