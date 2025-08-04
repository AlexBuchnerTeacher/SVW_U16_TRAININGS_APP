import 'package:flutter/material.dart';

class TrainingCard extends StatelessWidget {
  final String datum;
  final String details;

  const TrainingCard({super.key, required this.datum, required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(datum, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(details),
          ],
        ),
      ),
    );
  }
}
