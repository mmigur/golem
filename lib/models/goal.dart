class Goal {
  final String id;
  final DateTime deadline;
  final String title;
  final String description;
  final String afterParams;
  final String doneParams;
  final String profileId;

  Goal({
    required this.id,
    required this.deadline,
    required this.title,
    required this.description,
    required this.afterParams,
    required this.doneParams,
    required this.profileId,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] ?? '',
      deadline: DateTime.parse(map['deadline']),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      afterParams: map['after_params'] ?? '',
      doneParams: map['done_params'] ?? '',
      profileId: map['profile_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deadline': deadline.toIso8601String(),
      'title': title,
      'description': description,
      'after_params': afterParams,
      'done_params': doneParams,
      'profile_id': profileId,
    };
  }
}