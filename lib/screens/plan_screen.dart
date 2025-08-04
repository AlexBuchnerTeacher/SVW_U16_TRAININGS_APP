import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_day.dart';
import '../widgets/training_card.dart';
import '../widgets/player_card.dart';

class PlanScreen extends StatefulWidget {
  final Function(int completed, int total)? onProgressChanged;

  const PlanScreen({super.key, this.onProgressChanged});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  List<TrainingDay> trainingDays = [];
  bool isLoading = true;

  // Status-Daten
  Map<String, Map<String, bool>> subtaskStatus = {}; // Unterübungen
  Map<String, String> notes = {};
  Map<String, int> feelingRatings = {};
  Map<String, int> effortRatings = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await loadTrainingData();
    await loadPreferences();
    widget.onProgressChanged?.call(getCompletedCount(), trainingDays.length);
  }

  // JSON laden
  Future<void> loadTrainingData() async {
    final String response =
        await rootBundle.loadString('assets/data/trainingsplan.json');
    final List<dynamic> data = json.decode(response);
    trainingDays = data.map((json) => TrainingDay.fromJson(json)).toList();
  }

  // Preferences laden
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      subtaskStatus = _decodeNestedBoolMap(prefs.getString('subtaskStatus'));
      notes = _decodeStringMap(prefs.getString('notes'));
      feelingRatings = _decodeIntMap(prefs.getString('feelingRatings'));
      effortRatings = _decodeIntMap(prefs.getString('effortRatings'));
      isLoading = false;
    });
  }

  // Preferences speichern
  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subtaskStatus', json.encode(subtaskStatus));
    await prefs.setString('notes', json.encode(notes));
    await prefs.setString('feelingRatings', json.encode(feelingRatings));
    await prefs.setString('effortRatings', json.encode(effortRatings));
  }

  // Dekodier-Helfer
  Map<String, Map<String, bool>> _decodeNestedBoolMap(String? data) {
    if (data == null) return {};
    final Map<String, dynamic> decoded = json.decode(data);
    return decoded.map((key, value) =>
        MapEntry(key, Map<String, bool>.from(value as Map)));
  }

  Map<String, String> _decodeStringMap(String? data) {
    return data != null ? Map<String, String>.from(json.decode(data)) : {};
  }

  Map<String, int> _decodeIntMap(String? data) {
    return data != null ? Map<String, int>.from(json.decode(data)) : {};
  }

  // Abhak-Logik: Tag erledigt, wenn alle Unterübungen true sind
  bool isDayCompleted(String datum, bool mo5esActive) {
    final subtasks = subtaskStatus[datum] ?? {};
    final laufen = subtasks['laufen'] ?? false;
    final dehnen = subtasks['dehnen'] ?? false;
    final mo5es = mo5esActive ? (subtasks['mo5es'] ?? false) : true;

    return laufen && dehnen && mo5es;
  }

  // Gesamtfortschritt berechnen
  int getCompletedCount() {
    int count = 0;
    for (final day in trainingDays) {
      if (isDayCompleted(day.datum, day.mo5es)) count++;
    }
    return count;
  }

  // Callback, wenn etwas geändert wird
  void updateAndSave() {
    savePreferences();
    widget.onProgressChanged?.call(getCompletedCount(), trainingDays.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainingsplan'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Spieler-Card oben
                const PlayerCard(
                  name: 'Jonas',
                  position: 'Offensives Mittelfeld',
                  age: 15,
                  imagePath: 'assets/images/jonas.png',
                ),

                // Fortschrittsanzeige
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${getCompletedCount()} von ${trainingDays.length} Tagen erledigt',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: getCompletedCount() / trainingDays.length,
                        backgroundColor: Colors.grey[300],
                        color: Colors.black,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),

                // Liste der TrainingCards
                Expanded(
                  child: ListView.builder(
                    itemCount: trainingDays.length,
                    itemBuilder: (context, index) {
                      final day = trainingDays[index];

                      // Initialisiere Unterübungen, falls nicht vorhanden
                      subtaskStatus[day.datum] ??= {
                        "laufen": false,
                        "mo5es": false,
                        "dehnen": false,
                      };

                      return TrainingCard(
                        day: day,
                        subtasks: subtaskStatus[day.datum]!,
                        notes: notes[day.datum] ?? '',
                        feeling: feelingRatings[day.datum] ?? 0,
                        effort: effortRatings[day.datum] ?? 0,
                        onSubtaskChanged: (task, value) {
                          subtaskStatus[day.datum]![task] = value;
                          updateAndSave();
                        },
                        onNoteChanged: (text) {
                          notes[day.datum] = text;
                          updateAndSave();
                        },
                        onFeelingChanged: (value) {
                          feelingRatings[day.datum] = value;
                          updateAndSave();
                        },
                        onEffortChanged: (value) {
                          effortRatings[day.datum] = value;
                          updateAndSave();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
