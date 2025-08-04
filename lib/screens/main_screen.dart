import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'plan_screen.dart';
import 'diagramm_screen.dart';
import 'info_screen.dart';
import 'topics_screen.dart';
import 'goals_screen.dart';
import 'trainer_screen.dart';

class MainScreen extends StatefulWidget {
  final String? role;   // Trainer oder Spieler
  final String? userId; // Falls Trainer: gewählter Spieler

  const MainScreen({super.key, this.role, this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _completedDays = 0;
  bool _isTrainer = false;
  late String _activeUserId;

  List<Widget>? _screens; // nullable statt late

  @override
  void initState() {
    super.initState();
    _initUserIdAndRole();
  }

  Future<void> _initUserIdAndRole() async {
    // 1. Trainer wählt Spieler
    if (widget.userId != null) {
      _activeUserId = widget.userId!;
      _isTrainer = widget.role == 'trainer';
      _buildScreens();
      return;
    }

    // 2. Sonst: eingeloggter User selbst
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _activeUserId = currentUser.uid;

      // Rolle laden
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (doc.exists && doc.data()?['role'] == 'trainer') {
        _isTrainer = true;
      }
      _buildScreens();
    }
  }

  void _buildScreens() {
    _screens = [
      PlanScreen(userId: _activeUserId, onProgressChanged: _updateProgress),
      DiagrammScreen(userId: _activeUserId),
      const InfoScreen(),
      TopicsScreen(userId: _activeUserId),
      GoalsScreen(userId: _activeUserId),
      if (_isTrainer) const TrainerScreen(),
    ];
    setState(() {});
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
    if (_screens == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _screens![_selectedIndex],
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
          if (_isTrainer)
            const BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Spieler',
            ),
        ],
      ),
    );
  }
}
