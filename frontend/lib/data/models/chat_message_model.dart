import 'package:equatable/equatable.dart';

class ChatMessageModel extends Equatable {
  final int id;
  final int? turtleId;
  final String role; // user / assistant
  final String content;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    this.turtleId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as int,
      turtleId: json['turtleId'] as int?,
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'turtleId': turtleId,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ChatMessageModel copyWith({
    int? id,
    int? turtleId,
    String? role,
    String? content,
    DateTime? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      turtleId: turtleId ?? this.turtleId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, turtleId, role, content, createdAt];
}
