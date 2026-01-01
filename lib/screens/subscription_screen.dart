import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../models/user_session.dart';

enum PricingPlan { weekly, monthly }

class SubscriptionScreen extends StatefulWidget {
  final String userId;

  const SubscriptionScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  PricingPlan _selectedPlan = PricingPlan.monthly;
  late AnimationController _animationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startSubscription() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 선택된 플랜 타입 결정
      final planType =
          _selectedPlan == PricingPlan.weekly ? 'weekly' : 'monthly';

      // 구독 API 호출
      final updatedSession = await _apiClient.subscribe(
        userId: widget.userId,
        planType: planType,
      );

      if (!mounted) return;

      // SharedPreferences에 프리미엄 상태 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', updatedSession.isPremium);

      // 성공 시 홈 화면으로 돌아가기 (프리미엄 상태 반영)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('프리미엄 구독이 완료되었습니다! 🎉'),
          backgroundColor: const Color(0xFFD4A5A5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      // 홈 화면으로 돌아가기 (결과 전달)
      Navigator.pop(context, true); // true = 구독 성공
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('구독 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFF8B3A62),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC8879E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '프리미엄 플랜',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF8F3),
              const Color(0xFFFFF0E6),
              const Color(0xFFFFE4E1).withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // 1. 헤더 (맨 위)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFE4E1).withOpacity(0.5),
                              const Color(0xFFFFD4D4).withOpacity(0.3),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          size: 64,
                          color: Color(0xFFE89BB5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFE89BB5), Color(0xFF8B3A62)],
                      ).createShader(bounds),
                      child: const Text(
                        '무제한으로\n완벽한 답장을',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '프리미엄으로 더 많은 기능을 경험하세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF8B3A62).withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 2. 가격 플랜 선택
                    _buildSectionTitle('플랜 선택'),
                    const SizedBox(height: 16),
                    _buildPricingOption(
                      plan: PricingPlan.weekly,
                      title: '주간 플랜',
                      price: '₩1,900',
                      period: '주',
                      isRecommended: false,
                    ),
                    const SizedBox(height: 12),
                    _buildPricingOption(
                      plan: PricingPlan.monthly,
                      title: '월간 플랜',
                      price: '₩4,900',
                      period: '월',
                      isRecommended: true,
                    ),
                    const SizedBox(height: 40),

                    // 3. 혜택 리스트 (2개만)
                    _buildSectionTitle('프리미엄 혜택'),
                    const SizedBox(height: 16),
                    _buildBenefitCard(
                      icon: Icons.all_inclusive,
                      title: '무제한 메시지 생성',
                      description: '횟수 제한 없이 언제든지 리즈 생성',
                      index: 0,
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitCard(
                      icon: Icons.block,
                      title: '광고 없는 깨끗한 경험',
                      description: '방해 없이 순수한 서비스 이용',
                      index: 1,
                    ),
                    const SizedBox(height: 80), // 버튼 공간 확보
                  ],
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'serif',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8B3A62),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.15;
        final adjustedValue =
            (_animationController.value - delay).clamp(0.0, 1.0);
        final slideOffset = (1 - adjustedValue) * 30;
        final opacity = adjustedValue;

        return Transform.translate(
          offset: Offset(0, slideOffset),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD4D4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE89BB5).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD4D4), Color(0xFFFFE4E1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: const Color(0xFF8B3A62),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B3A62),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF8B3A62).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPricingOption({
    required PricingPlan plan,
    required String title,
    required String price,
    required String period,
    required bool isRecommended,
  }) {
    final isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFFB5B5), Color(0xFFE89BB5)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE89BB5)
                : const Color(0xFFFFD4D4),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE89BB5)
                  .withOpacity(isSelected ? 0.15 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFFFFD4D4),
                  width: 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Color(0xFFE89BB5),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF8B3A62),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : const Color(0xFFFFD700).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFFFD700),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '추천',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected ? Colors.white : const Color(0xFFE89BB5),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$price/$period',
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : const Color(0xFF8B3A62).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD4D4).withOpacity(0.5),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _startSubscription,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isLoading
                    ? [
                        const Color(0xFFD4A5A5).withOpacity(0.5),
                        const Color(0xFFE89BB5).withOpacity(0.5),
                      ]
                    : const [
                        Color(0xFFFFB5B5),
                        Color(0xFFE89BB5),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFFE89BB5).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '프리미엄 시작하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
