class Task {
  final String id;
  final String goalId;
  final String profileId;
  final String title;
  final String description;
  final bool isComplete;
  final DateTime deadline;
  final DateTime? completedAt;
  final String? doneParams;

  Task({
    required this.id,
    required this.goalId,
    required this.profileId,
    required this.title,
    required this.description,
    required this.isComplete,
    required this.deadline,
    this.completedAt,
    this.doneParams,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      profileId: json['profile_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isComplete: json['isComplete'] as bool? ?? false,
      deadline: DateTime.parse(json['deadline'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      doneParams: json['done_params'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'profile_id': profileId,
      'title': title,
      'description': description,
      'isComplete': isComplete,
      'deadline': deadline.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'done_params': doneParams,
    };
  }
} 