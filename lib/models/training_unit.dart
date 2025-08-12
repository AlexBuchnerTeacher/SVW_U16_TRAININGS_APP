class TrainingUnit {
  final String id;
  final String type; // Laufen | Mo5es | Mobility | Technik | Match
  final int duration;
  final String? pace; // nur Laufen (optional)
  final String description; // optional
  final int intensity; // 1..5
  final bool completed;

  // --- Laufen ---
  final String laufArt;     // Pflicht bei Laufen
  final String pulsRange;   // abgeleitet aus laufArt

  // --- Mo5es ---
  final String mo5esFocus;  // "Core, Sprungkraft, Stabilität"

  // --- Mobility ---
  final String mobilityFocus;  // "Hüftbeuger, Adduktoren, Hamstrings, Waden"
  final String pulsHinweis;    // "Puls < 123 bpm (regenerativ)"

  // --- Technik ---
  final List<String> technikZiele; // mind. 1
  final int technikBewertung;      // 1..5

  // --- Match ---
  final List<String> matchZiele;        // exakt 3
  final List<int> matchBewertungen;     // Länge 3, 1..5

  TrainingUnit({
    required this.id,
    required this.type,
    required this.duration,
    required this.pace,
    required this.description,
    required this.intensity,
    required this.completed,
    // Laufen
    this.laufArt = '',
    this.pulsRange = '',
    // Mo5es
    this.mo5esFocus = '',
    // Mobility
    this.mobilityFocus = '',
    this.pulsHinweis = '',
    // Technik
    this.technikZiele = const [],
    this.technikBewertung = 0,
    // Match
    this.matchZiele = const [],
    this.matchBewertungen = const [],
  });

  factory TrainingUnit.fromMap(String id, Map<String, dynamic> data) {
    int toInt(dynamic v, [int fb = 0]) {
      if (v is int) return v;
      if (v is double) return v.round();
      return int.tryParse(v?.toString() ?? '') ?? fb;
    }

    List<int> toIntList(dynamic v) {
      if (v is List) {
        return v.map((e) => toInt(e, 0)).toList();
      }
      return const [];
    }

    List<String> toStringList(dynamic v) {
      if (v is List) {
        return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return const [];
    }

    List<String> padToLen(List<String> lst, int len, String fill) {
      final res = List<String>.from(lst);
      while (res.length < len) {
        res.add(fill);
      }
      if (res.length > len) {
        return res.sublist(0, len);
      }
      return res;
    }

    final type = (data['type']?.toString() ?? '').trim();

    // Abwärtskompatibilität: alte Felder mappen
    final legacyGoals = toStringList(data['goals']);
    final legacyLaufart = data['laufart']?.toString() ?? '';

    // Technik/Match Heuristik (falls aus Altbestand)
    List<String> technikZiele = toStringList(data['technikZiele']);
    int technikBewertung = toInt(data['technikBewertung'], 0);

    List<String> matchZiele = toStringList(data['matchZiele']);
    List<int> matchBewertungen = toIntList(data['matchBewertungen']);

    if (type == 'Technik' && technikZiele.isEmpty && legacyGoals.isNotEmpty) {
      technikZiele = legacyGoals;
      if (technikBewertung == 0) technikBewertung = 3;
    }
    if (type == 'Match' && matchZiele.isEmpty && legacyGoals.isNotEmpty) {
      matchZiele = padToLen(legacyGoals, 3, ''); // statt padRight auf List
      if (matchBewertungen.isEmpty) {
        matchBewertungen = [3, 3, 3];
      } else if (matchBewertungen.length < 3) {
        matchBewertungen = [
          ...matchBewertungen,
          ...List<int>.filled(3 - matchBewertungen.length, 3)
        ];
      } else if (matchBewertungen.length > 3) {
        matchBewertungen = matchBewertungen.sublist(0, 3);
      }
    }

    // Laufen
    final laufArt = (data['laufArt']?.toString() ?? legacyLaufart).trim();
    final pulsRange = data['pulsRange']?.toString() ?? '';

    return TrainingUnit(
      id: id,
      type: type,
      duration: toInt(data['duration']),
      pace: (data['pace']?.toString().trim().isNotEmpty ?? false)
          ? data['pace'].toString().trim()
          : null,
      description: data['description']?.toString() ?? '',
      intensity: toInt(data['intensity'], 3).clamp(1, 5),
      completed: (data['completed'] ?? false) == true,
      // Laufen
      laufArt: laufArt,
      pulsRange: pulsRange,
      // Mo5es
      mo5esFocus: data['mo5esFocus']?.toString() ?? '',
      // Mobility
      mobilityFocus: data['mobilityFocus']?.toString() ?? '',
      pulsHinweis: data['pulsHinweis']?.toString() ?? '',
      // Technik
      technikZiele: technikZiele,
      technikBewertung: technikBewertung.clamp(0, 5),
      // Match
      matchZiele: matchZiele,
      matchBewertungen: matchBewertungen.isEmpty
          ? const []
          : matchBewertungen.map((e) => e.clamp(1, 5)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'duration': duration,
      if (pace != null) 'pace': pace,
      'description': description,
      'intensity': intensity,
      'completed': completed,
      // Laufen
      if (laufArt.isNotEmpty) 'laufArt': laufArt,
      if (pulsRange.isNotEmpty) 'pulsRange': pulsRange,
      // Mo5es
      if (mo5esFocus.isNotEmpty) 'mo5esFocus': mo5esFocus,
      // Mobility
      if (mobilityFocus.isNotEmpty) 'mobilityFocus': mobilityFocus,
      if (pulsHinweis.isNotEmpty) 'pulsHinweis': pulsHinweis,
      // Technik
      if (technikZiele.isNotEmpty) 'technikZiele': technikZiele,
      if (technikBewertung > 0) 'technikBewertung': technikBewertung,
      // Match
      if (matchZiele.isNotEmpty) 'matchZiele': matchZiele,
      if (matchBewertungen.isNotEmpty) 'matchBewertungen': matchBewertungen,
    };
  }
}
