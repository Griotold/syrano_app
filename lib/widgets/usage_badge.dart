import 'package:flutter/material.dart';

class UsageBadge extends StatelessWidget {
  final int usedCount;
  final int totalCount;
  final bool isPremium;
  final VoidCallback? onTap;

  const UsageBadge({
    super.key,
    required this.usedCount,
    required this.totalCount,
    required this.isPremium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 프리미엄 사용자
    if (isPremium) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD700), // 골드
              Color(0xFFFFA500), // 오렌지
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'PRO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        ),
      );
    }

    // 무료 사용자
    final isWarning = usedCount >= totalCount;
    final remainingCount = totalCount - usedCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFE4E1) : const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isWarning ? const Color(0xFFFF6B6B) : const Color(0xFFE89BB5),
          width: isWarning ? 2 : 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarning ? Icons.warning_outlined : Icons.favorite_outline,
            size: 16,
            color:
                isWarning ? const Color(0xFFFF6B6B) : const Color(0xFF8B3A62),
          ),
          const SizedBox(width: 4),
          Text(
            '$remainingCount/$totalCount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isWarning
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF8B3A62),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
