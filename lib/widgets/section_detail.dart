import 'package:flutter/material.dart';

class SectionDetail extends StatelessWidget {
  final String title;
  final String value;
  final String pulse;

  const SectionDetail({
    super.key,
    required this.title,
    required this.value,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),

          // Inhalt
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),

          // Pulsbereich dezent
          if (pulse.isNotEmpty)
            Text(
              pulse,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          const Divider(height: 16, thickness: 0.5),
        ],
      ),
    );
  }
}
