import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main_screen.dart';

class TrainerScreen extends StatefulWidget {
  const TrainerScreen({super.key});

  @override
  State<TrainerScreen> createState() => _TrainerScreenState();
}

class _TrainerScreenState extends State<TrainerScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    // Alle Spieler laden (role == player)
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'player')
        .get();

    List<Map<String, dynamic>> loadedPlayers = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // Fortschritt berechnen
      final planSnapshot =
          await _firestore.collection('users').doc(doc.id).collection('plan').get();

      final totalDays = planSnapshot.docs.length;
      final completedDays = planSnapshot.docs.where((d) {
        final subtasks = Map<String, dynamic>.from(d.data()['subtasks'] ?? {});
        return (subtasks['laufen'] ?? false) &&
            (subtasks['dehnen'] ?? false) &&
            (subtasks['mo5es'] ?? false);
      }).length;

      double progress = totalDays > 0 ? completedDays / totalDays : 0;

      loadedPlayers.add({
        'id': doc.id,
        'name': data['name'] ?? '',
        'position': data['position'] ?? '',
        'age': data['age'] ?? 0,
        'imagePath': data['imagePath'] ?? '',
        'progress': progress,
      });
    }

    setState(() {
      players = loadedPlayers;
      isLoading = false;
    });
  }

  void _openPlayer(String playerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          role: 'trainer',
          userId: playerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spielerübersicht'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : players.isEmpty
              ? const Center(child: Text('Keine Spieler gefunden'))
              : ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: player['imagePath'] != ''
                              ? AssetImage(player['imagePath'])
                              : null,
                          backgroundColor: Colors.grey[300],
                          radius: 24,
                          child: player['imagePath'] == ''
                              ? const Icon(Icons.person, color: Colors.black)
                              : null,
                        ),
                        title: Text(
                          player['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player['position']),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: player['progress'],
                              backgroundColor: Colors.grey[300],
                              color: Colors.green,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(player['progress'] * 100).toStringAsFixed(0)}% erledigt',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () => _openPlayer(player['id']),
                      ),
                    );
                  },
                ),
    );
  }
}
