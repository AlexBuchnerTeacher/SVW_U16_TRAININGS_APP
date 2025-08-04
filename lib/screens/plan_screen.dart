import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/training_day.dart';
import '../widgets/training_card.dart';
import '../widgets/player_card.dart';

class PlanScreen extends StatefulWidget {
  final String userId; // Spieler-ID
  final Function(int completed, int total)? onProgressChanged;

  const PlanScreen({super.key, required this.userId, this.onProgressChanged});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  List<TrainingDay> trainingDays = [];
  bool isLoading = true;

  Map<String, Map<String, bool>> subtaskStatus = {};
  Map<String, String> notes = {};
  Map<String, int> feelingRatings = {};
  Map<String, int> effortRatings = {};

  final _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  String? firstOpenDay;
  String? flashDay; // Für den gelben Flash

  // Keys für jede Card
  final Map<String, GlobalKey> cardKeys = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await loadTrainingData();
    await loadFromFirestore();
    widget.onProgressChanged?.call(getCompletedCount(), trainingDays.length);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFirstOpenDay();
    });
  }

  Future<void> loadTrainingData() async {
    final String response =
        await rootBundle.loadString('assets/data/trainingsplan.json');
    final List<dynamic> data = json.decode(response);
    trainingDays = data.map((json) => TrainingDay.fromJson(json)).toList();
  }

  Future<void> loadFromFirestore() async {
    final planRef =
        _firestore.collection('users').doc(widget.userId).collection('plan');
    final snapshot = await planRef.get();

    Map<String, Map<String, bool>> subtasks = {};
    Map<String, String> userNotes = {};
    Map<String, int> feelings = {};
    Map<String, int> efforts = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final datum = doc.id;

      subtasks[datum] = Map<String, bool>.from(data['subtasks'] ?? {
        "laufen": false,
        "mo5es": false,
        "dehnen": false,
      });

      userNotes[datum] = data['note'] ?? '';
      feelings[datum] = (data['feeling'] ?? 0) as int;
      efforts[datum] = (data['effort'] ?? 0) as int;
    }

    // Neue Tage ergänzen
    for (var day in trainingDays) {
      if (!subtasks.containsKey(day.datum)) {
        subtasks[day.datum] = {
          "laufen": false,
          "mo5es": false,
          "dehnen": false,
        };
        userNotes[day.datum] = '';
        feelings[day.datum] = 0;
        efforts[day.datum] = 0;

        await planRef.doc(day.datum).set({
          "subtasks": subtasks[day.datum],
          "note": '',
          "feeling": 0,
          "effort": 0,
        });
      }
    }

    // Ersten offenen Tag bestimmen
    firstOpenDay = _getFirstOpenDay(subtasks);

    setState(() {
      subtaskStatus = subtasks;
      notes = userNotes;
      feelingRatings = feelings;
      effortRatings = efforts;
      isLoading = false;
    });
  }

  String? _getFirstOpenDay(Map<String, Map<String, bool>> subtasks) {
    for (final day in trainingDays) {
      if (!isDayCompleted(day.datum, day.mo5es)) {
        return day.datum;
      }
    }
    return null;
  }

  void _scrollToFirstOpenDay() {
    if (firstOpenDay == null) return;

    final key = cardKeys[firstOpenDay];
    final index = trainingDays.indexWhere((d) => d.datum == firstOpenDay);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key?.currentContext != null) {
        // Exakter Scroll mit ensureVisible
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      } else if (index != -1) {
        // Fallback mit animateTo
        _scrollController.animateTo(
          index * 190.0, // geschätzte Höhe pro Card
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }

      // Farbflash aktivieren
      setState(() => flashDay = firstOpenDay);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => flashDay = null);
      });
    });
  }

  Future<void> saveToFirestore(String datum) async {
    final docRef = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('plan')
        .doc(datum);
    await docRef.set({
      "subtasks": subtaskStatus[datum],
      "note": notes[datum],
      "feeling": feelingRatings[datum],
      "effort": effortRatings[datum],
    }, SetOptions(merge: true));

    widget.onProgressChanged?.call(getCompletedCount(), trainingDays.length);

    setState(() {
      firstOpenDay = _getFirstOpenDay(subtaskStatus);
    });

    // Scroll erneut ausführen, falls sich der erste offene Tag verschiebt
    _scrollToFirstOpenDay();
  }

  bool isDayCompleted(String datum, bool mo5esActive) {
    final subtasks = subtaskStatus[datum] ?? {};
    final laufen = subtasks['laufen'] ?? false;
    final dehnen = subtasks['dehnen'] ?? false;
    final mo5es = mo5esActive ? (subtasks['mo5es'] ?? false) : true;
    return laufen && dehnen && mo5es;
  }

  int getCompletedCount() {
    int count = 0;
    for (final day in trainingDays) {
      if (isDayCompleted(day.datum, day.mo5es)) count++;
    }
    return count;
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
                // Spieler-Info
                FutureBuilder<DocumentSnapshot>(
                  future:
                      _firestore.collection('users').doc(widget.userId).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: PlayerCard(
                        name: data['name'] ?? '',
                        position: data['position'] ?? '',
                        age: data['age'] ?? 0,
                        imagePath: data['imagePath'] ??
                            'assets/images/placeholder.png',
                      ),
                    );
                  },
                ),

                // Fortschrittsbalken
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

                // TrainingCards
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: trainingDays.length,
                    itemBuilder: (context, index) {
                      final day = trainingDays[index];
                      final highlight = day.datum == firstOpenDay;
                      final completed = isDayCompleted(day.datum, day.mo5es);
                      final flash = day.datum == flashDay;

                      return TrainingCard(
                        key: cardKeys.putIfAbsent(day.datum, () => GlobalKey()),
                        day: day,
                        subtasks: subtaskStatus[day.datum]!,
                        notes: notes[day.datum] ?? '',
                        feeling: feelingRatings[day.datum] ?? 0,
                        effort: effortRatings[day.datum] ?? 0,
                        highlight: highlight,
                        completed: completed,
                        flash: flash,
                        onSubtaskChanged: (task, value) {
                          setState(() {
                            subtaskStatus[day.datum]![task] = value;
                          });
                          saveToFirestore(day.datum);
                        },
                        onNoteChanged: (text) {
                          notes[day.datum] = text;
                          saveToFirestore(day.datum);
                        },
                        onFeelingChanged: (value) {
                          feelingRatings[day.datum] = value;
                          saveToFirestore(day.datum);
                        },
                        onEffortChanged: (value) {
                          effortRatings[day.datum] = value;
                          saveToFirestore(day.datum);
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
