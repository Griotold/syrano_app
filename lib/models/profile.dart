/// 사용자 프로필 데이터 모델 (백엔드 스키마 일치)
class Profile {
  final String id; // 백엔드 UUID
  final String userId; // 사용자 ID
  final String name;
  final int age;
  final String gender;
  final String? memo; // MBTI 정보는 여기 포함
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.gender,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON 역직렬화 (백엔드 스키마)
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// JSON 직렬화 (백엔드 스키마)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'age': age,
      'gender': gender,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 프로필 복사 (일부 값 변경)
  Profile copyWith({
    String? id,
    String? userId,
    String? name,
    int? age,
    String? gender,
    String? memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
