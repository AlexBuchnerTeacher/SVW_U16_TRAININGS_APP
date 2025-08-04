import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/training_day.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  List<TrainingDay> trainingDays = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTrainingData();
  }

  Future<void> loadTrainingData() async {
    final String response =
        await rootBundle.loadString('assets/data/trainingsplan.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      trainingDays = data.map((json) => TrainingDay.fromJson(json)).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trainingsplan')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: trainingDays.length,
              itemBuilder: (context, index) {
                final day = trainingDays[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      '${day.datum} – ${day.laufart}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      buildSubtitle(day),
                    ),
                    trailing: day.mo5es
                        ? const Icon(Icons.fitness_center, color: Colors.black)
                        : null,
                  ),
                );
              },
            ),
    );
  }

  String buildSubtitle(TrainingDay day) {
    if (day.laufart == 'Intervalle') {
      return '${day.intervalleSprints} Sprints • Dehnen: ${day.dehnen} Min • Progression: ${day.progression}';
    } else if (day.laufart == 'Fahrtspiel') {
      return '${day.fahrtspielDauer} Min Fahrtspiel • Dehnen: ${day.dehnen} Min • Progression: ${day.progression}';
    } else {
      return '${day.laufDauer} Min GA • Dehnen: ${day.dehnen} Min • Progression: ${day.progression}';
    }
  }
}
