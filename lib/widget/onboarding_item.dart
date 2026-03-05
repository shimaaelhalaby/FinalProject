import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:to_do_app/model/onboarding_model.dart';

Column onboardingItem({required OnboardingModel model, required controller}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(model.image),
      SizedBox(height: 50),
      SmoothPageIndicator(
        controller: controller, // PageController
        count: 3,
        effect: ExpandingDotsEffect(
          dotHeight: 8,
          dotWidth: 8,
          activeDotColor: Colors.white,
          dotColor: Colors.white54,
          expansionFactor: 3,
          spacing: 4,
        ),
        onDotClicked: (index) {
          controller.animateToPage(
            index,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      ),
      SizedBox(height: 51),
      Text(
        model.title,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          fontFamily: "Lato",
          color: Colors.white,
        ),
      ),
      SizedBox(height: 42),
      Text(
        model.desc,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: "Lato",
          color: Colors.white.withValues(alpha: .87),
        ),
      ),
    ],
  );
}
