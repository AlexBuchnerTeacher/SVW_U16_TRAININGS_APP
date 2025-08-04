import 'package:flutter/material.dart';
import 'plan_screen.dart';
import 'diagramm_screen.dart';
import 'info_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  int _completedDays = 0; // Nur noch benötigtes Feld

  // Callback aus PlanScreen für Fortschritt
  void _updateProgress(int completed, int total) {
    setState(() {
      _completedDays = completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PlanScreen(onProgressChanged: _updateProgress),
      const DiagrammScreen(),
      const InfoScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/sv_waldeck_logo.png',
              height: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              'SV Waldeck Trainingsplan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: pages[_currentIndex],

      // BottomNavigationBar (Material 3 NavigationBar)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.fitness_center),
                if (_completedDays > 0)
                  Positioned(
                    right: -6,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$_completedDays',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Plan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Diagramm',
          ),
          const NavigationDestination(
            icon: Icon(Icons.info_outline),
            label: 'Info',
          ),
        ],
      ),
    );
  }
}
