import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/training_topic.dart';

class GoalsScreen extends StatefulWidget {
  final String userId;

  const GoalsScreen({super.key, required this.userId});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Map<String, dynamic>> allGoals = [];
  bool isLoading = true;

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadPredefinedGoals();
    await _loadSavedGoalsFromFirestore();
    setState(() {
      isLoading = false;
    });
  }

  /// Vordefinierte Ziele aus JSON laden
  Future<void> _loadPredefinedGoals() async {
    final String response =
        await rootBundle.loadString('assets/data/training_topics.json');
    final List<dynamic> data = json.decode(response);
    final topics = data.map((json) => TrainingTopic.fromJson(json)).toList();

    allGoals = topics
        .map((t) => {
              "id": t.id,
              "title": t.title,
              "description": t.description,
              "error_patterns": t.errorPatterns,
              "solutions": t.solutions,
              "training_drills": t.trainingDrills,
              "selected": false,
              "isCustom": false,
            })
        .toList();
  }

  /// Gespeicherte Daten aus Firestore laden
  Future<void> _loadSavedGoalsFromFirestore() async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('meta')
          .doc('goals');
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint("⚠️ Keine gespeicherten Ziele gefunden");
        return;
      }

      final data = doc.data();
      if (data == null) return;

      // Vorgegebene Ziele als ausgewählt markieren
      final predefinedSelected = List<String>.from(data['predefinedGoals'] ?? []);
      for (var goal in allGoals) {
        if (predefinedSelected.contains(goal["id"].toString())) {
          goal["selected"] = true;
        }
      }

      // Eigene Ziele hinzufügen
      final customGoals = List<Map<String, dynamic>>.from(data['customGoals'] ?? []);
      allGoals.addAll(customGoals);
    } catch (e, st) {
      debugPrint("Fehler beim Laden der Ziele: $e\n$st");
    }
  }

  /// Ziele speichern
  Future<void> _saveGoalsToFirestore() async {
    final predefinedIds = allGoals
        .where((g) => g["isCustom"] == false && g["selected"] == true)
        .map((g) => g["id"].toString())
        .toList();

    final customGoals = allGoals.where((g) => g["isCustom"] == true).toList();

    final docRef = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('meta')
        .doc('goals');
    await docRef.set({
      'predefinedGoals': predefinedIds,
      'customGoals': customGoals,
    });
  }

  void _toggleGoal(int index, bool isSelected) {
    setState(() {
      allGoals[index]["selected"] = isSelected;
    });
    _saveGoalsToFirestore();
  }

  void _addCustomGoal(String title, String description) {
    setState(() {
      allGoals.add({
        "id": DateTime.now().millisecondsSinceEpoch,
        "title": title,
        "description": description,
        "error_patterns": [],
        "solutions": [],
        "training_drills": [],
        "selected": false,
        "isCustom": true,
      });
    });
    _saveGoalsToFirestore();
  }

  void _editCustomGoal(int index, String newTitle, String newDescription) {
    setState(() {
      allGoals[index]["title"] = newTitle;
      allGoals[index]["description"] = newDescription;
    });
    _saveGoalsToFirestore();
  }

  void _deleteCustomGoal(int index) {
    setState(() {
      allGoals.removeAt(index);
    });
    _saveGoalsToFirestore();
  }

  Future<void> _showAddGoalDialog({int? editIndex}) async {
    final bool isEdit = editIndex != null;
    final TextEditingController titleController = TextEditingController(
      text: isEdit ? allGoals[editIndex]["title"] : '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: isEdit ? allGoals[editIndex]["description"] : '',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Ziel bearbeiten' : 'Neues Ziel hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                  });
                }
              },
              child: Text(isEdit ? 'Speichern' : 'Hinzufügen'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (isEdit) {
        _editCustomGoal(editIndex, result['title']!, result['description']!);
      } else {
        _addCustomGoal(result['title']!, result['description']!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Trainingsziele'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: allGoals.length,
              itemBuilder: (context, index) {
                final goal = allGoals[index];

                return Dismissible(
                  key: Key(goal["id"].toString()),
                  direction: goal["isCustom"]
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  onDismissed: (_) {
                    _deleteCustomGoal(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ziel gelöscht')),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: GestureDetector(
                    onLongPress: () {
                      if (goal["isCustom"]) {
                        _showAddGoalDialog(editIndex: index);
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      child: ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                goal["title"],
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Checkbox(
                              value: goal["selected"],
                              onChanged: (value) =>
                                  _toggleGoal(index, value ?? false),
                            ),
                          ],
                        ),
                        children: [
                          if (goal["description"] != null &&
                              goal["description"].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(goal["description"]),
                            ),
                          if (goal["error_patterns"] != null &&
                              goal["error_patterns"].isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Häufige Fehler:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ...goal["error_patterns"].map<Widget>((e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: Text("• $e"),
                                )),
                          ],
                          if (goal["solutions"] != null &&
                              goal["solutions"].isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Lösungen:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ...goal["solutions"].map<Widget>((e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: Text("• $e"),
                                )),
                          ],
                          if (goal["training_drills"] != null &&
                              goal["training_drills"].isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Übungen:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ...goal["training_drills"].map<Widget>((e) =>
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: Text("• $e"),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
