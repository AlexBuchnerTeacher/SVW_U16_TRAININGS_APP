import 'package:flutter/material.dart';

class RatingRow extends StatefulWidget {
  final int currentRating;
  final bool isFeeling; // true = Gefühl (Smilies), false = Anstrengung (Flammen)
  final ValueChanged<int> onRatingChanged;

  const RatingRow({
    super.key,
    required this.currentRating,
    required this.isFeeling,
    required this.onRatingChanged,
  });

  @override
  State<RatingRow> createState() => _RatingRowState();
}

class _RatingRowState extends State<RatingRow> {
  int? _tappedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Beschriftung oberhalb der Icons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.isFeeling ? 'Schwach' : 'Keine',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              widget.isFeeling ? 'Sehr stark' : 'Maximum',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 2),

        // Icons zentriert
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final ratingValue = index + 1;
            final isSelected = ratingValue <= widget.currentRating;

            final Color color = _ratingColor(ratingValue);
            final bool isTapped = _tappedIndex == index;

            return GestureDetector(
              onTapDown: (_) {
                setState(() => _tappedIndex = index);
              },
              onTapUp: (_) {
                setState(() => _tappedIndex = null);
                widget.onRatingChanged(ratingValue);
              },
              onTapCancel: () {
                setState(() => _tappedIndex = null);
              },
              child: AnimatedScale(
                scale: isTapped ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 44, // Einheitliche Breite
                  height: 44, // Einheitliche Höhe
                  alignment: Alignment.center,
                  child: Icon(
                    widget.isFeeling
                        ? _feelingIcon(ratingValue)
                        : Icons.whatshot,
                    size: 30,
                    color: isSelected ? color : Colors.grey[400],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Smilies für Gefühl
  IconData _feelingIcon(int value) {
    switch (value) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  // Farbskala: Rot → Gelb → Grün
  Color _ratingColor(int value) {
    switch (value) {
      case 1:
        return Colors.red.shade300;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.amber.shade400;
      case 4:
        return Colors.lightGreen.shade400;
      case 5:
        return Colors.green.shade500;
      default:
        return Colors.grey;
    }
  }
}
