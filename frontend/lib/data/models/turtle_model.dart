import 'package:equatable/equatable.dart';

class TurtleModel extends Equatable {
  final int id;
  final String name;
  final String species;
  final DateTime? birthDate;
  final double? weight;
  final double? shellLength;
  final DateTime? adoptDate;
  final String? photoUrl;
  final String? notes;
  final bool isActive;

  const TurtleModel({
    required this.id,
    required this.name,
    required this.species,
    this.birthDate,
    this.weight,
    this.shellLength,
    this.adoptDate,
    this.photoUrl,
    this.notes,
    this.isActive = true,
  });

  factory TurtleModel.fromJson(Map<String, dynamic> json) {
    return TurtleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      species: json['species'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      weight: (json['weight'] as num?)?.toDouble(),
      shellLength: (json['shellLength'] as num?)?.toDouble(),
      adoptDate: json['adoptDate'] != null
          ? DateTime.parse(json['adoptDate'] as String)
          : null,
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'birthDate': birthDate?.toIso8601String(),
      'weight': weight,
      'shellLength': shellLength,
      'adoptDate': adoptDate?.toIso8601String(),
      'photoUrl': photoUrl,
      'notes': notes,
      'isActive': isActive,
    };
  }

  TurtleModel copyWith({
    int? id,
    String? name,
    String? species,
    DateTime? birthDate,
    double? weight,
    double? shellLength,
    DateTime? adoptDate,
    String? photoUrl,
    String? notes,
    bool? isActive,
  }) {
    return TurtleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      shellLength: shellLength ?? this.shellLength,
      adoptDate: adoptDate ?? this.adoptDate,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, species, birthDate, weight, shellLength, adoptDate, photoUrl, notes, isActive];
}
