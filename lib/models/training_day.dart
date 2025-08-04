class TrainingDay {
  final String datum;
  final String laufart; // GA, Fahrtspiel, Intervalle
  final int? laufDauer; // Minuten
  final int? intervalleSprints; // Anzahl
  final bool mo5es;
  final int dehnen; // Minuten
  final String progression;

  TrainingDay({
    required this.datum,
    required this.laufart,
    this.laufDauer,
    this.intervalleSprints,
    required this.mo5es,
    required this.dehnen,
    required this.progression,
  });

  factory TrainingDay.fromJson(Map<String, dynamic> json) {
    return TrainingDay(
      datum: json['datum'],
      laufart: json['laufart'],
      laufDauer: json['lauf_dauer'],
      intervalleSprints: json['intervalle_sprints'],
      mo5es: json['mo5es'],
      dehnen: json['dehnen'],
      progression: json['progression'],
    );
  }
}
