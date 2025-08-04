class TrainingDay {
  final String datum;
  final String laufart;
  final int? laufDauer;
  final int? intervalleSprints;
  final int? fahrtspielDauer;
  final bool mo5es;
  final int dehnen;
  final String progression;

  TrainingDay({
    required this.datum,
    required this.laufart,
    this.laufDauer,
    this.intervalleSprints,
    this.fahrtspielDauer,
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
      fahrtspielDauer: json['fahrtspiel_dauer'],
      mo5es: json['mo5es'],
      dehnen: json['dehnen'],
      progression: json['progression'],
    );
  }
}
