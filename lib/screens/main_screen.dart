import 'package:flutter/material.dart';

import 'plan_screen.dart';
import 'diagramm_screen.dart';
import 'info_screen.dart';
import 'topics_screen.dart';
import 'goals_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _completedDays = 0;

late final List<Widget> _screens;

@override
void initState() {
  super.initState();
  _screens = [
    PlanScreen(onProgressChanged: _updateProgress),
    const DiagrammScreen(),
    const InfoScreen(),
    const TopicsScreen(),
    const GoalsScreen(),
  ];
}

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateProgress(int completed, int total) {
    setState(() {
      _completedDays = completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.fitness_center),
                if (_completedDays > 0)
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$_completedDays',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Plan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Diagramme',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Info',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Themen',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: 'Ziele',
          ),
        ],
      ),
    );
  }
}
