class UserSession {
  final String userId;
  final bool isPremium;

  const UserSession({
    required this.userId,
    required this.isPremium,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['user_id'] as String,
      isPremium: (json['is_premium'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'is_premium': isPremium,
    };
  }

  UserSession copyWith({
    String? userId,
    bool? isPremium,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}