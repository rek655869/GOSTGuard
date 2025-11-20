import 'package:flutter/material.dart';
import '../features/checking_drawing/checking_screen.dart';
import '../features/gosts/gosts_screen.dart';
import '../features/history/history_screen.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Проверка',
          ),
          NavigationDestination(
            icon: Icon(Icons.star),
            label: 'ГОСТы',
          ),
          NavigationDestination(
            icon: Icon(Icons.archive),
            label: 'История',
          ),
        ],
      ),
      body: [
        CheckingScreen(),
        GostsScreen(),
        HistoryScreen(),
      ][currentPageIndex],
    );
  }
}
