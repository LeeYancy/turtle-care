import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final int id;
  final int turtleId;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.turtleId,
    required this.title,
    required this.description,
    required this.scheduledTime,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      turtleId: json['turtleId'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'turtleId': turtleId,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    int? id,
    int? turtleId,
    String? title,
    String? description,
    DateTime? scheduledTime,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      turtleId: turtleId ?? this.turtleId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, turtleId, title, description, scheduledTime, isCompleted, completedAt, createdAt];
}
