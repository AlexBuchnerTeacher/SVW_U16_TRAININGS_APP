import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import '../models/training_day.dart';
import '../models/training_unit.dart';
import '../widgets/edit_training_sheet.dart';
import '../widgets/player_card.dart';
import '../widgets/training_card.dart';

class PlanScreen extends StatefulWidget {
  final String userId; // Spieler-ID
  final Function(int completed, int total)? onProgressChanged;

  /// Optionen für Technik-Mehrfachauswahl (Überschriften aus Tab "Themen")
  final List<String> technikZielOptionen;

  const PlanScreen({
    super.key,
    required this.userId,
    this.onProgressChanged,
    this.technikZielOptionen = const [],
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  List<TrainingDay> trainingDays = [];
  final Map<String, List<TrainingUnit>> _unitsByDate = {};

  bool isLoading = true;
  String? firstOpenDay;
  String? flashDay;
  final Map<String, GlobalKey> cardKeys = {};

  // ------------------- DATUMS-TOOLS (robust) -------------------

  DateTime? _tryParseWith(String input, String pattern, {String locale = 'de_DE'}) {
    try {
      return DateFormat(pattern, locale).parseStrict(input);
    } catch (_) {
      return null;
    }
  }

  // Zieht aus krummen Strings ein Datum raus ("18.08 Se" -> "18.08")
  String _extractDateToken(String raw) {
    final s = raw.trim();
    final match = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{2,4}|\d{1,2}\.\d{1,2}|\d{4}-\d{2}-\d{2})')
        .firstMatch(s);
    return match != null ? match.group(0)! : s;
  }

  /// Normiert beliebige Eingaben (z. B. "2025-08-18", "18.08.2025", "18.08 Se") auf "yyyy-MM-dd".
  String _normalizeDateKey(String raw) {
    String s = raw.trim();

    // ISO? -> direkt
    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (iso.hasMatch(s)) return s;

    // Unsaubere Strings: Wochentag/Text abtrennen
    s = _extractDateToken(s);

    // gängige deutsche Formate
    DateTime? dt = _tryParseWith(s, 'dd.MM.yyyy') ?? _tryParseWith(s, 'dd.MM.yy');

    // Nur Tag/Monat? -> aktuelles Jahr annehmen
    if (dt == null && RegExp(r'^\d{1,2}\.\d{1,2}$').hasMatch(s)) {
      final parts = s.split('.');
      final d = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final year = DateTime.now().year;
      dt = DateTime(year, m, d);
    }

    // Letzter Versuch: ISO-ähnlich
    dt ??= (() {
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    })();

    if (dt == null) {
      debugPrint('WARN: Konnte Datum nicht parsen: "$raw" – fallback auf heute.');
      dt = DateTime.now();
    }

    return DateFormat('yyyy-MM-dd').format(dt);
  }

  DateTime _parseDate(String any) {
    final key = _normalizeDateKey(any);
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  String _formatDate(String any) {
    final dt = _parseDate(any);
    return DateFormat('E, dd.MM.yyyy', 'de_DE').format(dt);
  }

  void _sortDays() {
    trainingDays.sort((a, b) => _parseDate(a.datum).compareTo(_parseDate(b.datum)));
  }

  // ------------------- INIT / LOAD -------------------

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      await _loadTrainingDaysFromJson();
      _sortDays();
      await _ensureFirestoreDocsExist();
      await _loadUnitsFromFirestore();

      _updateProgress();
      setState(() => isLoading = false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstOpenDay();
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  Future<void> _loadTrainingDaysFromJson() async {
    final String response =
        await rootBundle.loadString('assets/data/trainingsplan.json');
    final List<dynamic> data = json.decode(response);

    trainingDays = data.map((json) {
      final day = TrainingDay.fromJson(json);
      final normalized = _normalizeDateKey(day.datum);
      return TrainingDay(
        datum: normalized,
        laufart: day.laufart,
        laufDauer: day.laufDauer,
        intervalleSprints: day.intervalleSprints,
        fahrtspielDauer: day.fahrtspielDauer,
        mo5es: day.mo5es,
        dehnen: day.dehnen,
        progression: day.progression,
      );
    }).toList();
  }

  Future<void> _ensureFirestoreDocsExist() async {
    final planCol =
        _firestore.collection('users').doc(widget.userId).collection('plan');

    for (final day in trainingDays) {
      final docRef = planCol.doc(day.datum);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({'units': []});
      } else {
        final data = doc.data();
        if (data == null || data['units'] == null) {
          await docRef.set({'units': []}, SetOptions(merge: true));
        }
      }
    }
  }

  Future<void> _loadUnitsFromFirestore() async {
    _unitsByDate.clear();
    final planCol =
        _firestore.collection('users').doc(widget.userId).collection('plan');

    for (final day in trainingDays) {
      final doc = await planCol.doc(day.datum).get();
      final data = doc.data();
      final list = (data?['units'] as List?) ?? [];
      _unitsByDate[day.datum] = list.map((u) {
        final map = Map<String, dynamic>.from(u as Map);
        final id = (map['id']?.toString().trim().isNotEmpty ?? false)
            ? map['id'].toString()
            : DateTime.now().millisecondsSinceEpoch.toString();
        return TrainingUnit.fromMap(id, map);
      }).toList();
    }

    _sortDays();
    firstOpenDay = _getFirstOpenDay();
  }

  String? _getFirstOpenDay() {
    for (final day in trainingDays) {
      final units = _unitsByDate[day.datum] ?? [];
      if (units.isEmpty) return day.datum;
      final allCompleted = units.every((u) => u.completed);
      if (!allCompleted) return day.datum;
    }
    return null;
  }

  void _scrollToFirstOpenDay() {
    if (firstOpenDay == null) return;

    final key = cardKeys[firstOpenDay];
    final index = trainingDays.indexWhere((d) => d.datum == firstOpenDay);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      } else if (index != -1) {
        _scrollController.animateTo(
          index * 220.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }

      setState(() => flashDay = firstOpenDay);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => flashDay = null);
      });
    });
  }

  void _updateProgress() {
    int completed = 0;
    int total = 0;
    for (final day in trainingDays) {
      final units = _unitsByDate[day.datum] ?? [];
      total += units.length;
      completed += units.where((u) => u.completed).length;
    }
    widget.onProgressChanged?.call(completed, total);
  }

  // ------------------- SAVE / MUTATION -------------------

  Future<void> _saveUnitsForDate(String date) async {
    final units = _unitsByDate[date] ?? [];
    final payload = units.map((u) => u.toMap()..['id'] = u.id).toList();

    await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('plan')
        .doc(date)
        .set({'units': payload}, SetOptions(merge: true));

    setState(() {
      firstOpenDay = _getFirstOpenDay();
    });
    _updateProgress();
  }

  Future<Map<String, dynamic>?> _showEditTrainingSheet({TrainingUnit? initial}) {
    return showEditTrainingSheet(
      context: context,
      initial: initial,
      technikZielOptionen: widget.technikZielOptionen,
    );
  }

  Future<void> _openAddOrEdit({
    required String date,
    TrainingUnit? initial,
  }) async {
    final result = await _showEditTrainingSheet(initial: initial);
    if (result == null) return;

    final units = _unitsByDate[date] ?? [];

    TrainingUnit buildFromResult(String id, {required bool completed}) {
      return TrainingUnit(
        id: id,
        type: (result['type'] as String).trim(),
        duration: result['duration'] as int,
        pace: result['pace'] as String?,
        description: (result['description'] as String? ?? '').trim(),
        intensity: (result['intensity'] as int).clamp(1, 5),
        completed: completed,

        // Laufen
        laufArt: (result['laufArt'] as String? ?? '').trim(),
        pulsRange: (result['pulsRange'] as String? ?? '').trim(),

        // Mo5es
        mo5esFocus: (result['mo5esFocus'] as String? ?? '').trim(),

        // Mobility
        mobilityFocus: (result['mobilityFocus'] as String? ?? '').trim(),
        pulsHinweis: (result['pulsHinweis'] as String? ?? '').trim(),

        // Technik
        technikZiele: List<String>.from(result['technikZiele'] ?? const []),
        technikBewertung: (result['technikBewertung'] ?? 0) as int,

        // Match
        matchZiele: List<String>.from(result['matchZiele'] ?? const []),
        matchBewertungen: List<int>.from(result['matchBewertungen'] ?? const []),
      );
    }

    if (initial == null) {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      units.add(buildFromResult(newId, completed: false));
    } else {
      final idx = units.indexWhere((u) => u.id == initial.id);
      if (idx != -1) {
        units[idx] = buildFromResult(initial.id, completed: initial.completed);
      }
    }

    _unitsByDate[date] = units;
    await _saveUnitsForDate(date);
    if (mounted) setState(() {});
  }

  Future<void> _createNewDayAndAddUnit() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;
    if (!mounted) return;

    final newDateStr =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

    if (trainingDays.any((d) => d.datum == newDateStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dieser Tag existiert bereits.")),
      );
      return;
    }

    final newDay = TrainingDay(
      datum: newDateStr,
      laufart: '',
      mo5es: false,
      dehnen: 0,
      progression: '',
    );

    setState(() {
      trainingDays.add(newDay);
      _sortDays();
      _unitsByDate[newDateStr] = [];
    });

    await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('plan')
        .doc(newDateStr)
        .set({'units': []});

    _openAddOrEdit(date: newDateStr);
  }

  Future<void> _deleteUnit(String date, TrainingUnit unit) async {
    final units = _unitsByDate[date] ?? [];
    units.removeWhere((u) => u.id == unit.id);
    _unitsByDate[date] = units;
    await _saveUnitsForDate(date);
    if (mounted) setState(() {});
  }

  Future<void> _toggleCompleted(String date, TrainingUnit unit, bool value) async {
    final units = _unitsByDate[date] ?? [];
    final idx = units.indexWhere((u) => u.id == unit.id);
    if (idx != -1) {
      units[idx] = TrainingUnit(
        id: unit.id,
        type: unit.type,
        duration: unit.duration,
        pace: unit.pace,
        description: unit.description,
        intensity: unit.intensity,
        completed: value,

        // Laufen
        laufArt: unit.laufArt,
        pulsRange: unit.pulsRange,

        // Mo5es
        mo5esFocus: unit.mo5esFocus,

        // Mobility
        mobilityFocus: unit.mobilityFocus,
        pulsHinweis: unit.pulsHinweis,

        // Technik
        technikZiele: unit.technikZiele,
        technikBewertung: unit.technikBewertung,

        // Match
        matchZiele: unit.matchZiele,
        matchBewertungen: unit.matchBewertungen,
      );
      _unitsByDate[date] = units;
      await _saveUnitsForDate(date);
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteDay(String date) async {
    final units = _unitsByDate[date] ?? [];
    final count = units.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trainingstag löschen?'),
        content: Text(
          count == 0
              ? 'Tag $date endgültig löschen?'
              : 'Tag $date samt $count Einheiten endgültig löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Firestore: komplettes Dokument entfernen
    await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('plan')
        .doc(date)
        .delete();

    // Lokal entfernen
    trainingDays.removeWhere((d) => d.datum == date);
    _unitsByDate.remove(date);

    setState(() {
      _sortDays();
      firstOpenDay = _getFirstOpenDay();
    });
    _updateProgress();
  }

  // ------------------- UI -------------------

  @override
  Widget build(BuildContext context) {
    final totalUnits =
        _unitsByDate.values.fold<int>(0, (p, list) => p + list.length);
    final completedUnits = _unitsByDate.values
        .fold<int>(0, (p, list) => p + list.where((u) => u.completed).length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainingsplan'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewDayAndAddUnit,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tag + Einheit hinzufügen'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future:
                      _firestore.collection('users').doc(widget.userId).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: PlayerCard(
                        name: data['name'] ?? '',
                        position: data['position'] ?? '',
                        age: data['age'] ?? 0,
                        imagePath:
                            data['imagePath'] ?? 'assets/images/placeholder.png',
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completedUnits von $totalUnits Einheiten erledigt',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: totalUnits == 0
                            ? 0
                            : (completedUnits / totalUnits),
                        backgroundColor: Colors.grey[300],
                        color: Colors.black,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: trainingDays.length,
                    itemBuilder: (context, index) {
                      final day = trainingDays[index];
                      final units = _unitsByDate[day.datum] ?? [];
                      final anyNotCompleted = units.any((u) => !u.completed);
                      final highlight = day.datum == firstOpenDay;
                      final flash = day.datum == flashDay;

                      final cardColor = flash
                          ? Colors.yellow.shade100
                          : (units.isEmpty
                              ? Colors.grey.shade100
                              : (anyNotCompleted
                                  ? Colors.white
                                  : Colors.green.shade50));

                      return Container(
                        key: cardKeys.putIfAbsent(day.datum, () => GlobalKey()),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: highlight ? Colors.black : Colors.black12,
                            width: highlight ? 1.5 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(day.datum),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Einheit hinzufügen',
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => _openAddOrEdit(date: day.datum),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Mehr',
                                    onSelected: (v) {
                                      if (v == 'delete') _deleteDay(day.datum);
                                    },
                                    itemBuilder: (ctx) => const [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.redAccent),
                                            SizedBox(width: 8),
                                            Text('Tag löschen'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (units.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    'Noch keine Einheiten – füge die erste Einheit hinzu.',
                                    style: TextStyle(
                                      color: Colors.black.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ...units.map((u) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: TrainingCard(
                                    unit: u,
                                    onToggleCompleted: (val) =>
                                        _toggleCompleted(day.datum, u, val),
                                    onEdit: () =>
                                        _openAddOrEdit(date: day.datum, initial: u),
                                    onDelete: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Einheit löschen?'),
                                          content: Text(
                                              '„${u.type} – ${u.duration} Min“ endgültig löschen?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Abbrechen'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Löschen'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _deleteUnit(day.datum, u);
                                      }
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
