class TrainingTopic {
  final int id;
  final String title;
  final String description;
  final List<String> errorPatterns;
  final List<String> solutions;
  final List<String> trainingDrills;

  TrainingTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.errorPatterns,
    required this.solutions,
    required this.trainingDrills,
  });

  factory TrainingTopic.fromJson(Map<String, dynamic> json) {
    return TrainingTopic(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      errorPatterns: List<String>.from(json['error_patterns']),
      solutions: List<String>.from(json['solutions']),
      trainingDrills: List<String>.from(json['training_drills']),
    );
  }
}
