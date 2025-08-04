import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training & Pulsbereiche'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Pulsbereiche für Jonas (15 Jahre)',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPulseRow('Grundlagenausdauer (GA)', '133–154 bpm', '65–75 % HFmax'),
                _buildPulseRow('Fahrtspiel', '154–174 bpm', '75–85 % HFmax'),
                _buildPulseRow('Intervalle', '185–205 bpm', '90–100 % HFmax'),
                const SizedBox(height: 8),
                const Text(
                  'Hinweis: HFmax bei Jonas ≈ 206 – (0.7 × Alter) ≈ 196 bpm',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Trainingsziele',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• **Grundlagenausdauer:** Grundlage für längere Spiele, schnelle Regeneration'),
                Text('• **Fahrtspiel:** Wechsel zwischen schnellen und lockeren Phasen, verbessert Tempowechsel'),
                Text('• **Intervalle:** Maximale Sprintleistung und Explosivität'),
                Text('• **Mo5es:** Athletik, Core, Sprungkraft, Stabilität'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Dehnen & Mobility',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• Hüftbeuger (Ausfallschritte, Hüftkreise)'),
                Text('• Adduktoren (Seitliche Dehnung)'),
                Text('• Hamstrings (Beinrückseiten)'),
                Text('• Waden (Fersen runterdrücken)'),
                SizedBox(height: 8),
                Text(
                  'Tipp: Nach jedem Training 15–20 Minuten dehnen. Atme ruhig und halte jede Dehnung 20–30 Sekunden.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Hinweise zur Belastung',
            content: const Text(
              'Höre auf deinen Körper: Wenn du dich müde oder überlastet fühlst, '
              'passe das Training an (z. B. Intensität reduzieren oder Pausentage einlegen). '
              'Bei Schmerzen → Pause und ggf. Rücksprache mit Trainer/Physio.',
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSection({required String title, required Widget content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildPulseRow(String name, String range, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              range,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              percent,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
