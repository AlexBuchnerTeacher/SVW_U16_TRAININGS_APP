import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final String position;
  final int age;
  final String imagePath;

  const PlayerCard({
    super.key,
    required this.name,
    required this.position,
    required this.age,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Spielerbild links
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),

            // Infos rechts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Position: $position',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Alter: $age Jahre',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  // Kleiner Trainingsstatus
                  Row(
                    children: [
                      const Icon(Icons.fitness_center,
                          size: 16, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        'Sommer-Vorbereitung 2025',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
