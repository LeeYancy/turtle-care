import 'package:equatable/equatable.dart';

class HealthRecordModel extends Equatable {
  final int id;
  final int turtleId;
  final String analysisType;
  final String symptoms;
  final String aiDiagnosis;
  final String riskLevel; // low / medium / high
  final String recommendations;
  final DateTime createdAt;

  const HealthRecordModel({
    required this.id,
    required this.turtleId,
    required this.analysisType,
    required this.symptoms,
    required this.aiDiagnosis,
    required this.riskLevel,
    required this.recommendations,
    required this.createdAt,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: json['id'] as int,
      turtleId: json['turtleId'] as int,
      analysisType: json['analysisType'] as String? ?? 'symptom',
      symptoms: json['symptoms'] as String? ?? '',
      aiDiagnosis: json['aiDiagnosis'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? 'low',
      recommendations: json['recommendations'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'turtleId': turtleId,
      'analysisType': analysisType,
      'symptoms': symptoms,
      'aiDiagnosis': aiDiagnosis,
      'riskLevel': riskLevel,
      'recommendations': recommendations,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  HealthRecordModel copyWith({
    int? id,
    int? turtleId,
    String? analysisType,
    String? symptoms,
    String? aiDiagnosis,
    String? riskLevel,
    String? recommendations,
    DateTime? createdAt,
  }) {
    return HealthRecordModel(
      id: id ?? this.id,
      turtleId: turtleId ?? this.turtleId,
      analysisType: analysisType ?? this.analysisType,
      symptoms: symptoms ?? this.symptoms,
      aiDiagnosis: aiDiagnosis ?? this.aiDiagnosis,
      riskLevel: riskLevel ?? this.riskLevel,
      recommendations: recommendations ?? this.recommendations,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, turtleId, analysisType, symptoms, aiDiagnosis, riskLevel, recommendations, createdAt];
}
