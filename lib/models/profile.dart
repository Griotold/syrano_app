import 'dart:convert';

/// 사용자 프로필 데이터 모델
class Profile {
  final String id;
  final String name;
  final int age;
  final String mbti;
  final String gender;
  final String? memo;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.mbti,
    required this.gender,
    this.memo,
    required this.createdAt,
  });

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'mbti': mbti,
      'gender': gender,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSON 역직렬화
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      mbti: json['mbti'] as String,
      gender: json['gender'] as String,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 새 프로필 생성 (ID와 생성일시 자동 생성)
  factory Profile.create({
    required String name,
    required int age,
    required String mbti,
    required String gender,
    String? memo,
  }) {
    return Profile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      age: age,
      mbti: mbti,
      gender: gender,
      memo: memo,
      createdAt: DateTime.now(),
    );
  }

  /// 프로필 복사 (일부 값 변경)
  Profile copyWith({
    String? id,
    String? name,
    int? age,
    String? mbti,
    String? gender,
    String? memo,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      mbti: mbti ?? this.mbti,
      gender: gender ?? this.gender,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
