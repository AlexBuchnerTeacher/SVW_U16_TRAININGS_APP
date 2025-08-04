import 'package:flutter/material.dart';

class RatingRow extends StatelessWidget {
  final int currentRating;
  final bool isFeeling; // true = Gefühl, false = Anstrengung
  final Function(int) onRatingChanged;

  const RatingRow({
    super.key,
    required this.currentRating,
    required this.isFeeling,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final icons = isFeeling
        ? [
            Icons.sentiment_very_dissatisfied,
            Icons.sentiment_dissatisfied,
            Icons.sentiment_neutral,
            Icons.sentiment_satisfied,
            Icons.sentiment_very_satisfied
          ]
        : [
            Icons.local_fire_department,
            Icons.local_fire_department,
            Icons.local_fire_department,
            Icons.local_fire_department,
            Icons.local_fire_department
          ];

    return Row(
      children: List.generate(5, (index) {
        final ratingValue = index + 1;
        final isSelected = ratingValue <= currentRating;

        return IconButton(
          icon: Icon(
            icons[index],
            color: isFeeling
                ? (isSelected ? Colors.black : Colors.grey[400])
                : (isSelected ? Colors.redAccent : Colors.grey[400]),
          ),
          onPressed: () => onRatingChanged(ratingValue),
        );
      }),
    );
  }
}
