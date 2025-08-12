import 'package:flutter/material.dart';
import '../models/training_unit.dart';

class TrainingCard extends StatelessWidget {
  final TrainingUnit unit;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TrainingCard({
    super.key,
    required this.unit,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = unit.completed ? Colors.green.shade50 : Colors.white;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kopf
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _typeIcon(unit.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    unit.type,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(tooltip: 'Einheit bearbeiten', icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
                IconButton(tooltip: 'Einheit löschen', icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), onPressed: onDelete),
              ],
            ),

            const SizedBox(height: 6),
            // Meta (Dauer, Pace, Intensität)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _metaPill(icon: Icons.timer_outlined, label: '${unit.duration} Min'),
                if (_isRun(unit) && (unit.pace?.trim().isNotEmpty ?? false))
                  _metaPill(icon: Icons.directions_run, label: 'Pace ${unit.pace}'),
                _intensityPill(unit.intensity),
              ],
            ),

            // Typ-spezifische Sektionen
            const SizedBox(height: 10),
            if (unit.description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(unit.description, style: const TextStyle(fontSize: 14)),
              ),

            if (_isRun(unit)) _runSection(unit),
            if (unit.type == 'Mo5es') _mo5esSection(unit),
            if (unit.type == 'Mobility') _mobilitySection(unit),
            if (unit.type == 'Technik') _technikSection(unit),
            if (unit.type == 'Match') _matchSection(unit),

            const SizedBox(height: 6),
            // Completed Toggle
            Row(
              children: [
                Checkbox(
                  value: unit.completed,
                  onChanged: (v) => onToggleCompleted(v ?? false),
                  activeColor: Colors.black,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                const Text('Erledigt', style: TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isRun(TrainingUnit u) => u.type == 'Laufen';

  Widget _typeIcon(String type) {
    switch (type) {
      case 'Laufen':
        return const Icon(Icons.directions_run, color: Colors.blueAccent, size: 22);
      case 'Mo5es':
        return const Icon(Icons.fitness_center, color: Colors.deepPurple, size: 22);
      case 'Mobility':
        return const Icon(Icons.self_improvement, color: Colors.teal, size: 22);
      case 'Technik':
        return const Icon(Icons.flag, color: Colors.orange, size: 22);
      case 'Match':
        return const Icon(Icons.sports_soccer, color: Colors.blueGrey, size: 22);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 22);
    }
  }

  Widget _metaPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _intensityPill(int intensity) {
    final clamped = intensity.clamp(1, 5);
    final Map<int, Color> map = {
      1: Colors.green,
      2: Colors.teal,
      3: Colors.amber,
      4: Colors.orange,
      5: Colors.red,
    };
    final base = map[clamped] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: base.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withAlpha(64)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 16, color: base),
          const SizedBox(width: 6),
          Text('Intensität $clamped/5', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: base)),
        ],
      ),
    );
  }

  // --- Sections ---
  Widget _runSection(TrainingUnit u) {
    final chips = <Widget>[];
    if (u.laufArt.isNotEmpty) {
      chips.add(_chip(u.laufArt));
    }
    if (u.pulsRange.isNotEmpty) {
      chips.add(_chip(u.pulsRange, icon: Icons.favorite));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _mo5esSection(TrainingUnit u) {
    if (u.mo5esFocus.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: _chip(u.mo5esFocus, icon: Icons.info_outline),
    );
  }

  Widget _mobilitySection(TrainingUnit u) {
    final chips = <Widget>[];
    if (u.mobilityFocus.isNotEmpty) chips.add(_chip(u.mobilityFocus));
    if (u.pulsHinweis.isNotEmpty) chips.add(_chip(u.pulsHinweis, icon: Icons.favorite_border));
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _technikSection(TrainingUnit u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (u.technikZiele.isNotEmpty) ...[
          const Text('Trainingsziele', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: u.technikZiele.map((g) => _chip(g)).toList(),
          ),
          const SizedBox(height: 8),
        ],
        if (u.technikBewertung > 0)
          Row(
            children: [
              const Text('Wie lief’s: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Icon(_ratingIcon(u.technikBewertung)),
            ],
          ),
      ],
    );
  }

  Widget _matchSection(TrainingUnit u) {
    if (u.matchZiele.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(u.matchZiele.length, (i) {
        final ziel = u.matchZiele[i];
        final rating = (i < u.matchBewertungen.length) ? u.matchBewertungen[i] : 0;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(child: Text('• $ziel')),
              if (rating > 0) Icon(_ratingIcon(rating)),
            ],
          ),
        );
      }),
    );
  }

  IconData _ratingIcon(int v) {
    switch (v) {
      case 1: return Icons.sentiment_very_dissatisfied;
      case 2: return Icons.sentiment_dissatisfied;
      case 3: return Icons.sentiment_neutral;
      case 4: return Icons.sentiment_satisfied;
      default: return Icons.sentiment_very_satisfied;
    }
  }

  Widget _chip(String label, {IconData? icon}) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 4)],
          Text(label),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
