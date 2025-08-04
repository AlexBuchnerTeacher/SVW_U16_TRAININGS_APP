import 'dart:math';
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

  final bool highlight;
  final bool completed;
  final bool flash;

  final Function(String task, bool value) onSubtaskChanged;
  final Function(String text) onNoteChanged;
  final Function(int value) onFeelingChanged;
  final Function(int value) onEffortChanged;

  TrainingCard({
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
    this.highlight = false,
    this.completed = false,
    this.flash = false,
  });

  // Inspirierende Texte für Notizen
  static final List<String> hintTexts = [
    'Was hat dich heute stolz gemacht?',
    'Gab es einen Moment, der richtig Spaß gemacht hat?',
    'Was war deine größte Herausforderung heute?',
    'Was würdest du nächstes Mal besser machen wollen?',
    'Gab es etwas, das dich heute überrascht hat?',
  ];

  // Zufälliger Hinweistext
  final String randomHint = hintTexts[Random().nextInt(hintTexts.length)];

  @override
  Widget build(BuildContext context) {
    // Hintergrundfarbe je nach Status
    final cardColor = flash
        ? Colors.yellow[100] // Kurzzeit-Flash
        : completed
            ? Colors.green[50] // Abgeschlossen
            : highlight
                ? Colors.grey[200] // Erster offener Tag
                : Colors.white;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: highlight ? Colors.black : Colors.grey[300]!,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datum + Laufart
            Text(
              '${day.datum} – ${day.laufart}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Unterübungen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSubtaskCheckbox('Laufen', 'laufen'),
                if (day.mo5es) _buildSubtaskCheckbox('Mo5es', 'mo5es'),
                _buildSubtaskCheckbox('Dehnen', 'dehnen'),
              ],
            ),
            const Divider(height: 20),

            // Lauf-Details
            SectionDetail(
              title: 'Laufen',
              value: buildLaufenDetail(day),
              pulse: buildPulseRange(day.laufart),
            ),

            // Mo5es-Details
            if (day.mo5es)
              SectionDetail(
                title: 'Mo5es',
                value: '30 Min Athletiktraining\nFokus: Core, Sprungkraft, Stabilität',
                pulse: 'Kein Pulsbereich – saubere Ausführung wichtig',
              ),

            // Dehnen-Details
            SectionDetail(
              title: 'Dehnen',
              value:
                  '15–20 Min fußballspezifisch (Hüftbeuger, Adduktoren, Hamstrings, Waden)',
              pulse: '< 123 bpm (Regenerativ)',
            ),
            const Divider(height: 20),

            // Gefühl (Smilies) – Icons zentriert, Text darüber
            RatingRow(
              currentRating: feeling,
              isFeeling: true,
              onRatingChanged: onFeelingChanged,
            ),
            const SizedBox(height: 12),

            // Anstrengung (Flammen) – Icons zentriert, Text darüber
            RatingRow(
              currentRating: effort,
              isFeeling: false,
              onRatingChanged: onEffortChanged,
            ),
            const Divider(height: 20),

            // Notizenfeld mit Label + random Hint
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Notizen',
                hintText: randomHint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              minLines: 1,
              maxLines: 2,
              onChanged: onNoteChanged,
              controller: TextEditingController(text: notes),
            ),
          ],
        ),
      ),
    );
  }

  // Checkboxen
  Widget _buildSubtaskCheckbox(String label, String key) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: subtasks[key] ?? false,
          onChanged: (value) => onSubtaskChanged(key, value ?? false),
          activeColor: Colors.black,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // Lauf-Details
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

  // Pulsbereiche
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
