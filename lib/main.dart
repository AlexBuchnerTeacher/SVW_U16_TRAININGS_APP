import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const SVWTrainingApp());
}

class SVWTrainingApp extends StatelessWidget {
  const SVWTrainingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SV Waldeck U16 Trainingsplan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.black,
      ),
      home: const WelcomeScreen(),
    );
  }
}
