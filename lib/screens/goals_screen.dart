import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_topic.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Map<String, dynamic>> allGoals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadPredefinedGoals();
    await _loadSavedGoals();
    setState(() {
      isLoading = false;
    });
  }

  /// Vorgegebene Themen laden
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
              "selected": false,
              "isCustom": false,
            })
        .toList();
  }

  /// Gespeicherte Daten laden
  Future<void> _loadSavedGoals() async {
    final prefs = await SharedPreferences.getInstance();

    // Auswahl für vorgegebene Themen laden
    final savedPredefined = prefs.getStringList('selectedGoals') ?? [];
    for (var goal in allGoals) {
      if (savedPredefined.contains(goal["id"].toString())) {
        goal["selected"] = true;
      }
    }

    // Eigene Ziele laden
    final savedCustomGoals = prefs.getStringList('customGoals') ?? [];
    final customGoals = savedCustomGoals.map((e) {
      return Map<String, dynamic>.from(jsonDecode(e));
    }).toList();

    allGoals.addAll(customGoals);
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();

    // Vorgegebene Themen speichern
    final predefinedIds = allGoals
        .where((g) => g["isCustom"] == false && g["selected"] == true)
        .map((g) => g["id"].toString())
        .toList();
    await prefs.setStringList('selectedGoals', predefinedIds);

    // Eigene Ziele speichern
    final customGoals = allGoals.where((g) => g["isCustom"] == true).toList();
    await prefs.setStringList(
      'customGoals',
      customGoals.map((e) => jsonEncode(e)).toList(),
    );
  }

  void _toggleGoal(int index, bool isSelected) {
    setState(() {
      allGoals[index]["selected"] = isSelected;
    });
    _saveGoals();
  }

  void _addCustomGoal(String title, String description) {
    setState(() {
      allGoals.add({
        "id": DateTime.now().millisecondsSinceEpoch,
        "title": title,
        "description": description,
        "selected": false,
        "isCustom": true,
      });
    });
    _saveGoals();
  }

  void _editCustomGoal(int index, String newTitle, String newDescription) {
    setState(() {
      allGoals[index]["title"] = newTitle;
      allGoals[index]["description"] = newDescription;
    });
    _saveGoals();
  }

  void _deleteCustomGoal(int index) {
    setState(() {
      allGoals.removeAt(index);
    });
    _saveGoals();
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
                      child: ListTile(
                        title: Text(
                          goal["title"],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: goal["description"].isNotEmpty
                            ? Text(goal["description"])
                            : null,
                        trailing: Checkbox(
                          value: goal["selected"],
                          onChanged: (value) =>
                              _toggleGoal(index, value ?? false),
                        ),
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
