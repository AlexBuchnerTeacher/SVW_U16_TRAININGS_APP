import 'package:flutter/material.dart';

class DiagrammScreen extends StatelessWidget {
  const DiagrammScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fortschrittsdiagramm')),
      body: const Center(
        child: Text('Hier kommt das Diagramm'),
      ),
    );
  }
}
