import 'package:flutter/material.dart';
import '../models/training_day.dart';
import 'section_detail.dart';
import 'rating_row.dart';

class TrainingCard extends StatelessWidget {
  final TrainingDay day;
  final Map<String, bool> subtasks;
  final String notes;
  final int feeling;
  final int effort;

  final Function(String task, bool value) onSubtaskChanged;
  final Function(String text) onNoteChanged;
  final Function(int value) onFeelingChanged;
  final Function(int value) onEffortChanged;

  const TrainingCard({
    super.key,
    required this.day,
    required this.subtasks,
    required this.notes,
    required this.feeling,
    required this.effort,
    required this.onSubtaskChanged,
    required this.onNoteChanged,
    required this.onFeelingChanged,
    required this.onEffortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Datum + Laufart
            Text(
              '${day.datum} – ${day.laufart}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Unterübungen
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildSubtaskCheckbox('Laufen', 'laufen'),
                if (day.mo5es) _buildSubtaskCheckbox('Mo5es', 'mo5es'),
                _buildSubtaskCheckbox('Dehnen', 'dehnen'),
              ],
            ),
            const Divider(height: 24),

            // Sektionen mit Details
            SectionDetail(
              title: 'Laufen',
              value: buildLaufenDetail(day),
              pulse: buildPulseRange(day.laufart),
            ),
            if (day.mo5es)
              SectionDetail(
                title: 'Mo5es',
                value: '30 Min Athletiktraining\nFokus: Core, Sprungkraft, Stabilität',
                pulse: 'Kein Pulsbereich – saubere Ausführung wichtig',
              ),
            SectionDetail(
              title: 'Dehnen',
              value:
                  '15–20 Min fußballspezifisch (Hüftbeuger, Adduktoren, Hamstrings, Waden)',
              pulse: '< 123 bpm (Regenerativ)',
            ),
            const Divider(height: 24),

            // Bewertung Gefühl
            const Text(
              'Gefühl:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            RatingRow(
              currentRating: feeling,
              isFeeling: true,
              onRatingChanged: onFeelingChanged,
            ),
            const SizedBox(height: 12),

            // Bewertung Anstrengung
            const Text(
              'Anstrengung:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            RatingRow(
              currentRating: effort,
              isFeeling: false,
              onRatingChanged: onEffortChanged,
            ),
            const Divider(height: 24),

            // Notizfeld
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Notizen',
              ),
              minLines: 1,
              maxLines: 3,
              onChanged: onNoteChanged,
              controller: TextEditingController(text: notes),
            ),
          ],
        ),
      ),
    );
  }

  // Checkbox für Unterübungen
  Widget _buildSubtaskCheckbox(String label, String key) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: subtasks[key] ?? false,
          onChanged: (value) => onSubtaskChanged(key, value ?? false),
          activeColor: Colors.black,
        ),
        Text(label),
      ],
    );
  }

  // Laufen-Details je nach Laufart
  String buildLaufenDetail(TrainingDay day) {
    switch (day.laufart) {
      case 'Grundlagenausdauer':
        return '${day.laufDauer} Min gleichmäßig, locker';
      case 'Fahrtspiel':
        return '${day.fahrtspielDauer} Min: 2 Min schnell / 2 Min locker';
      case 'Intervalle':
        return '${day.intervalleSprints}× 20 Sek. Sprint / 20 Sek. Trab';
      default:
        return '';
    }
  }

  // Pulsbereiche je nach Laufart
  String buildPulseRange(String laufart) {
    switch (laufart) {
      case 'Grundlagenausdauer':
        return '133–154 bpm (65–75 % HFmax)';
      case 'Fahrtspiel':
        return '154–174 bpm (75–85 % HFmax)';
      case 'Intervalle':
        return '185–205 bpm (90–100 % HFmax)';
      default:
        return '';
    }
  }
}
