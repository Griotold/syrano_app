import 'package:flutter/material.dart';

/// 혜택 항목 위젯 (프리미엄 다이얼로그용)
Widget _buildBenefitItem(IconData icon, String text) {
  return Row(
    children: [
      Icon(
        icon,
        size: 20,
        color: const Color(0xFFE89BB5),
      ),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF8B3A62),
        ),
      ),
    ],
  );
}

/// 사용량 안내 다이얼로그 표시
void showUsageDialog(
  BuildContext context, {
  required bool isPremium,
  required int usedCount,
  required int totalCount,
}) {
  final remainingCount = totalCount - usedCount;

  // 프리미엄 사용자
  if (isPremium) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '프리미엄 회원',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8B3A62),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '무제한으로 사용하고 계세요! 🎉',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B3A62),
              ),
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(Icons.all_inclusive, '무제한 리즈 생성'),
            const SizedBox(height: 8),
            _buildBenefitItem(Icons.block, '광고 제거'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Color(0xFF8B3A62),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return;
  }

  // 무료 사용자 - 경고 레벨에 따라 다른 메시지
  String title;
  String message;
  Color iconColor;
  IconData icon;

  if (remainingCount == 0) {
    // 사용량 소진
    title = '오늘 사용량 모두 사용';
    message = '무료 사용자는 하루 5회까지 사용 가능해요.\n\n'
        '💎 프리미엄으로 업그레이드하면\n'
        '• 무제한 리즈 생성 (횟수 제한 없음)\n'
        '• 광고 완전 제거\n'
        '• 더 빠른 응답 속도';
    iconColor = const Color(0xFFFF6B6B);
    icon = Icons.warning_rounded;
  } else if (remainingCount == 1) {
    // 마지막 1회
    title = '마지막 1회 남음!';
    message = '오늘 사용 가능한 횟수가 1회 남았어요.\n\n'
        '💡 더 많이 사용하고 싶다면\n'
        '프리미엄을 고려해보세요!';
    iconColor = const Color(0xFFFF6B6B);
    icon = Icons.error_outline;
  } else if (remainingCount <= 2) {
    // 2회 이하 남음
    title = '$remainingCount회 남음';
    message = '오늘 사용 가능한 횟수가 얼마 남지 않았어요.\n\n'
        '프리미엄 회원은 무제한으로 사용할 수 있어요! ✨';
    iconColor = const Color(0xFFE89BB5);
    icon = Icons.info_outline;
  } else {
    // 3회 이상 남음
    title = '$remainingCount회 사용 가능';
    message = '오늘 $remainingCount회 더 사용할 수 있어요.\n\n'
        '무료 사용자는 하루 5회까지 사용 가능하며,\n'
        '매일 자정에 초기화돼요.';
    iconColor = const Color(0xFF8B3A62);
    icon = Icons.favorite;
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF8B3A62),
            ),
          ),
          if (remainingCount <= 1) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD4D4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.stars,
                    color: Color(0xFFE89BB5),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '프리미엄: 무제한 사용',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B3A62),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (remainingCount <= 1)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 구독 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('구독 화면은 곧 추가될 예정이에요!'),
                  backgroundColor: Color(0xFFE89BB5),
                ),
              );
            },
            child: const Text(
              '프리미엄 보기',
              style: TextStyle(
                color: Color(0xFFE89BB5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            remainingCount <= 1 ? '나중에' : '확인',
            style: const TextStyle(
              color: Color(0xFF8B3A62),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
