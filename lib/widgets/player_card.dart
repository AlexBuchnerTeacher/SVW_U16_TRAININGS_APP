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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Spielerbild – rund, hochauflösend
            ClipOval(
              child: Image.asset(
                imagePath,
                width: 90,   // etwas größer, um Schärfe zu erhöhen
                height: 90,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high, // beste Filterung
                isAntiAlias: true, // saubere Rundung
              ),
            ),
            const SizedBox(width: 14),

            // Spielerinfos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    '$position • $age Jahre',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.fitness_center,
                          size: 16, color: Colors.black54),
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
