import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:to_do_app/core/theme_app.dart';
import 'package:to_do_app/view/intro/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:to_do_app/core/sync_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SyncService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'To Do App',
      transitionDuration: Duration(milliseconds: 300),
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        fontFamily: 'Lato',
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Color.fromARGB(255, 28, 28, 28),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        scaffoldBackgroundColor: Colors.black,

        colorScheme: ColorScheme.fromSeed(seedColor: ThemeApp.primaryColor),
      ),
      home: const SplashScreen(),
    );
  }
}
