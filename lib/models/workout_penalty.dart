class WorkoutPenalty {
  final String id;
  final String title;
  final int reps;
  final String exercise;
  final String reason;
  final double excessAmount;
  final DateTime timestamp;
  bool isCompleted;

  WorkoutPenalty({
    required this.id,
    required this.title,
    required this.reps,
    required this.exercise,
    required this.reason,
    required this.excessAmount,
    required this.timestamp,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'reps': reps,
      'exercise': exercise,
      'reason': reason,
      'excessAmount': excessAmount,
      'timestamp': timestamp.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutPenalty.fromMap(Map<String, dynamic> map) {
    return WorkoutPenalty(
      id: map['id'] as String? ?? 'wp_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title'] as String? ?? '25 подтягиваний',
      reps: (map['reps'] as num?)?.toInt() ?? 25,
      exercise: map['exercise'] as String? ?? 'подтягиваний',
      reason: map['reason'] as String? ?? 'Превышение лимита',
      excessAmount: (map['excessAmount'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}
