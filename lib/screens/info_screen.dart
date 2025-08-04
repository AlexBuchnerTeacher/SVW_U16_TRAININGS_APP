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
          // --- Pulsbereiche ---
          _buildSection(
            icon: Icons.favorite,
            iconColor: Colors.redAccent,
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

          // --- Trainingsziele ---
          _buildSection(
            icon: Icons.flag,
            iconColor: Colors.blueAccent,
            title: 'Trainingsziele',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• Grundlagenausdauer: Grundlage für längere Spiele, schnelle Regeneration'),
                Text('• Fahrtspiel: Wechsel zwischen schnellen und lockeren Phasen, verbessert Tempowechsel'),
                Text('• Intervalle: Maximale Sprintleistung und Explosivität'),
                Text('• Mo5es: Athletik, Core, Sprungkraft, Stabilität'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Dehnen & Mobility ---
          _buildSection(
            icon: Icons.accessibility_new,
            iconColor: Colors.green,
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
                  'Tipp: Nach jedem Training 15–20 Minuten dehnen. Ruhig atmen und jede Dehnung 20–30 Sekunden halten.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Belastung ---
          _buildSection(
            icon: Icons.health_and_safety,
            iconColor: Colors.orange,
            title: 'Hinweise zur Belastung',
            content: const Text(
              'Höre auf deinen Körper: Wenn du dich müde oder überlastet fühlst, '
              'passe das Training an (z. B. Intensität reduzieren oder Pausentage einlegen). '
              'Bei Schmerzen → Pause und ggf. Rücksprache mit Trainer/Physio.',
            ),
          ),
          const SizedBox(height: 16),

          // --- Schlaf & Regeneration ---
          _buildSection(
            icon: Icons.bedtime,
            iconColor: Colors.indigo,
            title: 'Schlaf & Regeneration',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• 8–9 Stunden Schlaf pro Nacht anstreben'),
                Text('• Nach Spielen/Training Beine hochlegen und Flüssigkeit auffüllen'),
                Text('• Aktive Regeneration: lockeres Radfahren oder Spazierengehen am Folgetag'),
                SizedBox(height: 8),
                Text(
                  'Hinweis: Guter Schlaf ist entscheidend für Wachstum, Konzentration und Leistungssteigerung.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Ernährung ---
          _buildSection(
            icon: Icons.restaurant,
            iconColor: Colors.brown,
            title: 'Ernährung vor & nach dem Training',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• Vor dem Training: leicht verdauliche Kohlenhydrate (z. B. Banane, Toast)'),
                Text('• Während des Trainings: Wasser trinken, bei Hitze Elektrolyte zuführen'),
                Text('• Nach dem Training: Kombination aus Eiweiß & Kohlenhydraten (z. B. Joghurt + Obst)'),
                SizedBox(height: 8),
                Text(
                  'Tipp: Ausreichend trinken – 1,5 bis 2 Liter Wasser pro Tag plus zusätzlich bei Training/Spiel.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Mentale Stärke ---
          _buildSection(
            icon: Icons.psychology,
            iconColor: Colors.deepPurple,
            title: 'Mentale Stärke & Fokus',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• Vor dem Spiel ein klares Ziel setzen (z. B. „3 gute Flanken heute“)'),
                Text('• Fehler schnell abhaken und nächste Aktion fokussieren'),
                Text('• Positive Körpersprache auch bei Rückschlägen zeigen'),
                Text('• Visualisierung: Spielzüge und Erfolg vorher im Kopf durchgehen'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Technik-Check ---
          _buildSection(
            icon: Icons.check_circle_outline,
            iconColor: Colors.teal,
            title: 'Technik-Checkliste für Eigenkontrolle',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• Erster Kontakt in Spielrichtung?'),
                Text('• Kopf vor Ballannahme gehoben?'),
                Text('• Pass mit passendem Fuß & Winkel?'),
                Text('• Entscheidungsfindung: schnell & klar?'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Spielvorbereitung ---
          _buildSection(
            icon: Icons.sports_soccer,
            iconColor: Colors.blueGrey,
            title: 'Spielvorbereitung / Routine',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• 2–3 Stunden vor Spiel: letzte große Mahlzeit (leicht, kohlenhydratreich)'),
                Text('• Vor Abfahrt: 0,5 Liter Wasser trinken'),
                Text('• Eigenes Warm-up: Beweglichkeit, Sprungübungen, kurze Sprints'),
                Text('• Mentale Einstimmung: Musik, Visualisierung, Fokus auf 1–2 persönliche Ziele'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
