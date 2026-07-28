import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String phone;
  final String nickname;
  final String? avatar;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatar,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? phone,
    String? nickname,
    String? avatar,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, phone, nickname, avatar, createdAt];
}
