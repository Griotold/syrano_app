class UserSession {
  final String userId;
  final bool isPremium;
  final String? planType;     // "weekly" or "monthly"
  final DateTime? expiresAt;  // 구독 만료 시각

  const UserSession({
    required this.userId,
    required this.isPremium,
    this.planType,
    this.expiresAt,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['user_id'] as String,
      isPremium: (json['is_premium'] as bool?) ?? false,
      planType: json['plan_type'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'is_premium': isPremium,
      'plan_type': planType,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  UserSession copyWith({
    String? userId,
    bool? isPremium,
    String? planType,
    DateTime? expiresAt,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      isPremium: isPremium ?? this.isPremium,
      planType: planType ?? this.planType,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}