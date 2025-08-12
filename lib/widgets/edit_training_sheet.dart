import 'package:flutter/material.dart';
import '../models/training_unit.dart';

Future<Map<String, dynamic>?> showEditTrainingSheet({
  required BuildContext context,
  TrainingUnit? initial,
  required List<String> technikZielOptionen,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => EditTrainingSheet(
      initial: initial,
      technikZielOptionen: technikZielOptionen,
    ),
  );
}

class EditTrainingSheet extends StatefulWidget {
  final TrainingUnit? initial;
  final List<String> technikZielOptionen;

  const EditTrainingSheet({
    super.key,
    this.initial,
    required this.technikZielOptionen,
  });

  @override
  State<EditTrainingSheet> createState() => _EditTrainingSheetState();
}

class _EditTrainingSheetState extends State<EditTrainingSheet> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'Laufen';
  String _durationStr = '30';
  String? _pace;
  String _description = '';
  int _intensity = 3;

  String? _laufArt;
  final List<String> _laufArten = const [
    'gleichmäßig, locker',
    'Fahrtspiel 2 Min schnell / 2 Min locker',
    'Intervalle 10×20 s Sprint / 20 s Trab (evtl. 2–3 Serien)',
  ];

  final Set<String> _technikSelected = {};
  late final List<String> _technikOptions;
  int _technikBewertung = 3;

  final List<TextEditingController> _matchZielCtrls =
      List.generate(3, (_) => TextEditingController());
  final List<int> _matchBewertungen = [3, 3, 3];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;

    _type = _validOrDefaultType(i?.type);
    _durationStr = (i?.duration ?? 30).toString();
    _intensity = (i?.intensity ?? 3).clamp(1, 5);
    _description = i?.description ?? '';
    _pace = i?.pace;

    _laufArt = (i?.laufArt != null && _laufArten.contains(i!.laufArt)) ? i.laufArt : null;

    _technikOptions = [...widget.technikZielOptionen]..sort();
    if (_isTechnik && i?.technikZiele.isNotEmpty == true) {
      for (final g in i!.technikZiele) {
        if (_technikOptions.contains(g)) _technikSelected.add(g);
      }
      _technikBewertung = i.technikBewertung > 0 ? i.technikBewertung : 3;
    }

    if (_isMatch && i?.matchZiele.isNotEmpty == true) {
      for (var idx = 0; idx < 3; idx++) {
        _matchZielCtrls[idx].text = (idx < i!.matchZiele.length ? i.matchZiele[idx] : '');
        _matchBewertungen[idx] =
            (idx < i.matchBewertungen.length ? i.matchBewertungen[idx] : 3);
      }
    } else if (_isMatch) {
      _matchZielCtrls[0].text = '3 angekommene Flanken auf den Stürmer';
    }
  }

  @override
  void dispose() {
    for (final c in _matchZielCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isLaufen => _type == 'Laufen';
  bool get _isTechnik => _type == 'Technik';
  bool get _isMatch => _type == 'Match';
  bool get _isMo5es => _type == 'Mo5es';
  bool get _isMobility => _type == 'Mobility';

  String _validOrDefaultType(String? type) {
    const allowed = ['Laufen', 'Mo5es', 'Mobility', 'Technik', 'Match'];
    return allowed.contains(type) ? type! : 'Laufen';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final result = <String, dynamic>{
      'type': _type,
      'duration': int.tryParse(_durationStr) ?? 0,
      'description': _description.trim(),
      'intensity': _intensity,
    };

    if (_isLaufen) {
      result['pace'] = (_pace?.trim().isNotEmpty ?? false) ? _pace!.trim() : null;
      result['laufArt'] = _laufArt ?? '';
      result['pulsRange'] = _getPulsRange(_laufArt);
    }
    if (_isMo5es) {
      result['mo5esFocus'] = 'Core, Sprungkraft, Stabilität';
    }
    if (_isMobility) {
      result['mobilityFocus'] = 'Hüftbeuger, Adduktoren, Hamstrings, Waden';
      result['pulsHinweis'] = 'Puls < 123 bpm (regenerativ)';
    }
    if (_isTechnik) {
      result['technikZiele'] = _technikSelected.toList();
      result['technikBewertung'] = _technikBewertung;
    }
    if (_isMatch) {
      result['matchZiele'] = _matchZielCtrls.map((c) => c.text.trim()).toList();
      result['matchBewertungen'] = _matchBewertungen;
    }

    Navigator.of(context).pop(result);
  }

  String _getPulsRange(String? laufArt) {
    switch (laufArt) {
      case 'gleichmäßig, locker':
        return '133–154 bpm (65–75% HFmax)';
      case 'Fahrtspiel 2 Min schnell / 2 Min locker':
        return '154–174 bpm (75–85% HFmax)';
      case 'Intervalle 10×20 s Sprint / 20 s Trab (evtl. 2–3 Serien)':
        return '185–205 bpm (90–100% HFmax)';
      default:
        return '';
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Row(
          children: [
            Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Expanded(child: Divider(height: 1)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Section: Basis
                _sectionTitle('Einheit'),
                DropdownButtonFormField<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'Laufen', child: Text('Laufen')),
                    DropdownMenuItem(value: 'Mo5es', child: Text('Mo5es')),
                    DropdownMenuItem(value: 'Mobility', child: Text('Mobility')),
                    DropdownMenuItem(value: 'Technik', child: Text('Technik')),
                    DropdownMenuItem(value: 'Match', child: Text('Match')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'Laufen'),
                  decoration: _dec('Einheitentyp'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _durationStr,
                  decoration: _dec('Dauer (Minuten)'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Bitte > 0 eingeben',
                  onSaved: (v) => _durationStr = v ?? '0',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _description,
                  decoration: _dec('Beschreibung / Fokus (optional)'),
                  maxLines: 2,
                  onSaved: (v) => _description = v ?? '',
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: _dec('Intensität (1–5)'),
                  child: Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: _intensity.toDouble(),
                    label: '$_intensity',
                    onChanged: (v) => setState(() => _intensity = v.toInt()),
                  ),
                ),

                // Section: Laufen
                if (_isLaufen) ...[
                  _sectionTitle('Laufen'),
                  TextFormField(
                    initialValue: _pace,
                    decoration: _dec('Pace (mm:ss) – optional'),
                    onSaved: (v) => _pace = v?.isNotEmpty == true ? v : null,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return RegExp(r'^[0-9]{1,2}:[0-5][0-9]$').hasMatch(v.trim())
                          ? null
                          : 'Format mm:ss (z. B. 5:30)';
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _laufArt,
                    items: _laufArten
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (v) => setState(() => _laufArt = v),
                    validator: (v) => v != null ? null : 'Art des Laufens wählen',
                    decoration: _dec('Art des Laufens *'),
                  ),
                  if (_laufArt != null && _laufArt!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, size: 18),
                          const SizedBox(width: 6),
                          Text(_getPulsRange(_laufArt)),
                        ],
                      ),
                    ),
                ],

                // Section: Mo5es
                if (_isMo5es) ...[
                  _sectionTitle('Mo5es'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fokus: Core, Sprungkraft, Stabilität'),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 18),
                            SizedBox(width: 6),
                            Text('Saubere Ausführung ist wichtig.'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Section: Mobility
                if (_isMobility) ...[
                  _sectionTitle('Mobility'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fokus: Hüftbeuger, Adduktoren, Hamstrings, Waden'),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.favorite_border, size: 18),
                            SizedBox(width: 6),
                            Text('Puls < 123 bpm (regenerativ)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Section: Technik
                if (_isTechnik) ...[
                  _sectionTitle('Technik'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _technikOptions.map((ziel) {
                        final sel = _technikSelected.contains(ziel);
                        return FilterChip(
                          label: Text(ziel),
                          selected: sel,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _technikSelected.add(ziel);
                              } else {
                                _technikSelected.remove(ziel);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: _dec('Wie lief’s? (1–5)'),
                    child: Slider(
                      min: 1,
                      max: 5,
                      divisions: 4,
                      value: _technikBewertung.toDouble(),
                      label: '$_technikBewertung',
                      onChanged: (v) => setState(() => _technikBewertung = v.toInt()),
                    ),
                  ),
                ],

                // Section: Match
                if (_isMatch) ...[
                  _sectionTitle('Matchziele (genau 3)'),
                  for (var i = 0; i < 3; i++) ...[
                    TextFormField(
                      controller: _matchZielCtrls[i],
                      decoration: _dec('Matchziel ${i + 1}'),
                      validator: (v) =>
                          v != null && v.trim().isNotEmpty ? null : 'Ziel ${i + 1} angeben',
                    ),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: _dec('Bewertung Ziel ${i + 1}'),
                      child: Slider(
                        min: 1,
                        max: 5,
                        divisions: 4,
                        value: _matchBewertungen[i].toDouble(),
                        label: '${_matchBewertungen[i]}',
                        onChanged: (v) =>
                            setState(() => _matchBewertungen[i] = v.toInt()),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Abbrechen'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // zusätzliche Logik-Checks
                          if (_isLaufen && (_laufArt == null || _laufArt!.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bitte „Art des Laufens“ wählen.')),
                            );
                            return;
                          }
                          if (_isTechnik && _technikSelected.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mindestens ein Trainingsziel wählen.')),
                            );
                            return;
                          }
                          if (_isMatch &&
                              !_matchZielCtrls.every((c) => c.text.trim().isNotEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Alle 3 Matchziele ausfüllen.')),
                            );
                            return;
                          }
                          _save();
                        },
                        child: const Text('Speichern'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
