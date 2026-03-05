import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme_app.dart';
import 'package:to_do_app/view/home/fav_task_screen.dart';
import 'package:to_do_app/view/home/home_screen.dart';
import 'package:to_do_app/view/home/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<Widget> pages = [
    const HomeScreen(),
    const FavTaskScreen(),
    const ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        color: ThemeApp.primaryColor.withValues(alpha: 0.2),
        child: BottomNavigationBar(
          backgroundColor: ThemeApp.primaryColor.withValues(alpha: 0.2),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,

          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorite',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
