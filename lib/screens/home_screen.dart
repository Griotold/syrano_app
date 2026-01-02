import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_session.dart';
import '../models/profile.dart';
import '../services/api_client.dart';
import '../widgets/usage_badge.dart';
import '../widgets/usage_dialog.dart';
import 'profile_input_screen.dart';
import 'image_selection_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final ApiClient _apiClient = ApiClient();

  bool _isInitializing = true;
  UserSession? _session;
  List<Profile> _profiles = [];
  int _usedCount = 0;
  final int _totalCount = 5;

  String? get _userId => _session?.userId;
  bool get _isPremium => _session?.isPremium ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 화면 복귀 시 사용량 및 구독 상태 갱신
      _verifySubscription();
      _loadUsage();
    }
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ 이 한 줄만 추가!
    await prefs.remove('profiles');

    final savedUserId = prefs.getString('user_id');

    if (savedUserId != null) {
      // 백엔드에서 실제 구독 상태 검증
      try {
        final verifiedSession =
            await _apiClient.fetchSubscription(savedUserId);

        // SharedPreferences 업데이트 (서버가 진실 공급원)
        await prefs.setBool('is_premium', verifiedSession.isPremium);

        setState(() {
          _session = verifiedSession;
        });

        print(
            '✅ Subscription verified from backend: isPremium=${verifiedSession.isPremium}');
      } catch (e) {
        print('⚠️ Backend verification failed, using cached data: $e');

        // 네트워크 오류 시 로컬 캐시 사용 (fallback)
        final cachedPremium = prefs.getBool('is_premium') ?? false;
        setState(() {
          _session = UserSession(
            userId: savedUserId,
            isPremium: cachedPremium,
          );
        });
      }
    } else {
      // 최초 로그인
      try {
        final newSession = await _apiClient.anonymousLogin();
        await prefs.setString('user_id', newSession.userId);
        await prefs.setBool('is_premium', newSession.isPremium);
        setState(() {
          _session = newSession;
        });
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('익명 로그인 실패: $e', isError: true);
      }
    }

    // 프로필 목록 및 사용량 로드
    await _loadProfiles();
    await _loadUsage();

    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _verifySubscription() async {
    if (_userId == null) return;

    try {
      final verifiedSession = await _apiClient.fetchSubscription(_userId!);
      final prefs = await SharedPreferences.getInstance();

      // 이전 상태와 비교
      final previousPremiumStatus = _isPremium;
      final newPremiumStatus = verifiedSession.isPremium;

      // SharedPreferences 및 상태 업데이트
      await prefs.setBool('is_premium', newPremiumStatus);
      setState(() {
        _session = verifiedSession;
      });

      // 구독 상태가 변경된 경우 알림
      if (previousPremiumStatus && !newPremiumStatus) {
        // 프리미엄 → 무료 (구독 만료)
        if (!mounted) return;
        _showSnackBar('프리미엄 구독이 만료되었습니다.', isError: true);
        print('⚠️ Subscription expired');
      } else if (!previousPremiumStatus && newPremiumStatus) {
        // 무료 → 프리미엄 (새 구독)
        if (!mounted) return;
        _showSnackBar('프리미엄 구독이 활성화되었습니다! 🎉');
        print('✅ Subscription activated');
      } else {
        // 상태 변화 없음
        print('✅ Subscription status unchanged: isPremium=$newPremiumStatus');
      }
    } catch (e) {
      // 네트워크 오류 등으로 검증 실패 시 조용히 실패 (로컬 상태 유지)
      print('⚠️ Subscription verification failed on app resume: $e');
    }
  }

  Future<void> _loadProfiles() async {
    if (_userId == null) return;

    try {
      // API로 프로필 조회
      final profiles = await _apiClient.getProfiles(_userId!);
      setState(() {
        _profiles = profiles;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('프로필 로드 실패: $e', isError: true);
    }
  }

  Future<void> _loadUsage() async {
    if (_userId == null) return;

    try {
      final usage = await _apiClient.getUsage(_userId!);

      // 디버깅 출력
      print('==========================================');
      print('DEBUG: Usage API Response');
      print(usage);
      print('==========================================');

      setState(() {
        // 안전한 처리: 두 가지 케이스 모두 대응
        if (usage.containsKey('remaining_count')) {
          // Case A: remaining_count가 있으면 역계산
          final remaining = usage['remaining_count'] as int? ?? _totalCount;
          _usedCount = _totalCount - remaining;
          print('Using remaining_count: $_usedCount used, $remaining remaining');
        } else if (usage.containsKey('used_count')) {
          // Case B: used_count가 있으면 직접 사용
          _usedCount = usage['used_count'] as int? ?? 0;
          print('Using used_count: $_usedCount');
        } else {
          // Case C: 둘 다 없으면 기본값
          print('WARNING: No usage count in API response');
          _usedCount = 0;
        }
      });
    } catch (e) {
      print('Usage load failed: $e');
      // 에러 시 안전한 기본값
      setState(() {
        _usedCount = 0;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF8B3A62) : const Color(0xFFD4A5A5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSubscriptionInfo() {
    // 플랜 타입 한글 변환
    String planName = '월간 플랜';
    String planPrice = '₩4,900/월';

    if (_session?.planType == 'weekly') {
      planName = '주간 플랜';
      planPrice = '₩1,900/주';
    }

    // 만료일 포맷팅
    String expirationText = '정보 없음';
    if (_session?.expiresAt != null) {
      final expiresAt = _session!.expiresAt!;
      expirationText = '${expiresAt.year}년 ${expiresAt.month}월 ${expiresAt.day}일';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '프리미엄 구독 정보',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B3A62),
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 왕관 아이콘
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // 플랜 타입
            Text(
              planName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B3A62),
              ),
            ),
            const SizedBox(height: 8),

            // 다음 결제일
            Text(
              '다음 결제일: $expirationText',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF8B3A62).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),

            // 가격
            Text(
              planPrice,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF8B3A62).withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Color(0xFF8B3A62),
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 구독 관리 화면 (추후 구현)
              _showSnackBar('구독 관리 기능은 곧 추가될 예정입니다!');
            },
            child: const Text(
              '구독 관리',
              style: TextStyle(
                color: Color(0xFFE89BB5),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDaysUntilExpiration() {
    if (!_isPremium || _session?.expiresAt == null) {
      return 99; // 만료 없음
    }

    final now = DateTime.now();
    final expiresAt = _session!.expiresAt!;
    return expiresAt.difference(now).inDays;
  }

  Future<void> _navigateToProfileInput() async {
    if (_userId == null) {
      _showSnackBar('사용자 정보를 불러오지 못했어요. 다시 시도해주세요!', isError: true);
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileInputScreen(
          userId: _userId!,
        ),
      ),
    );

    if (result == true) {
      await _loadProfiles();
    }
  }

  Future<void> _navigateToImageSelection(Profile profile) async {
    if (_userId == null) {
      _showSnackBar('로그인 정보를 불러오지 못했어요. 다시 시도해주세요!', isError: true);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageSelectionScreen(
          profile: profile,
          userId: _userId!,
          usedCount: _usedCount,
          totalCount: _totalCount,
          isPremium: _isPremium,
        ),
      ),
    );

    // 화면 복귀 시 사용량 갱신
    await _loadUsage();
  }

  Future<void> _deleteProfile(Profile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로필 삭제'),
        content: Text('${profile.name} 프로필을 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Color(0xFF8B3A62))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // API로 프로필 삭제
        await _apiClient.deleteProfile(profile.id);
        await _loadProfiles();
        _showSnackBar('프로필이 삭제되었어요');
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('프로필 삭제 실패: $e', isError: true);
      }
    }
  }

  Widget _buildPremiumButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (_userId == null) {
            _showSnackBar('로그인 정보를 불러오지 못했어요. 다시 시도해주세요!',
                isError: true);
            return;
          }

          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => SubscriptionScreen(
                userId: _userId!,
              ),
            ),
          );

          // 구독 성공 시 전체 화면 새로고침
          if (result == true) {
            // SharedPreferences 다시 읽기 + 상태 업데이트
            final prefs = await SharedPreferences.getInstance();
            final isPremium = prefs.getBool('is_premium') ?? false;

            setState(() {
              _session = UserSession(
                userId: _userId!,
                isPremium: isPremium,
              );
            });

            // 사용량도 새로고침 (프리미엄이면 무제한)
            await _loadUsage();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB5B5), Color(0xFFE89BB5)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                '프리미엄 가입',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightBadge() {
    if (_isPremium) {
      // 프리미엄 배지 (탭 가능)
      return GestureDetector(
        onTap: _showSubscriptionInfo,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'PRO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 사용량 배지 (기존)
      return UsageBadge(
        usedCount: _usedCount,
        totalCount: _totalCount,
        isPremium: _isPremium,
        onTap: () => showUsageDialog(
          context,
          isPremium: _isPremium,
          usedCount: _usedCount,
          totalCount: _totalCount,
          userId: _userId,
        ),
      );
    }
  }

  Widget _buildSettingsButton() {
    return IconButton(
      icon: const Icon(
        Icons.settings_outlined,
        color: Colors.white,
        size: 24,
      ),
      onPressed: () {
        // TODO: 설정 화면 구현 후 네비게이션 추가
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('설정 화면은 곧 추가될 예정입니다!'),
            backgroundColor: const Color(0xFFD4A5A5),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC8879E),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Syrano',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        actions: [
          // 무료 유저만: 프리미엄 버튼 (왼쪽)
          if (!_isPremium) ...[
            const SizedBox(width: 16),
            _buildPremiumButton(),
          ],

          const Spacer(), // 오른쪽으로 밀기

          // 사용량 또는 PRO 배지
          _buildRightBadge(),
          const SizedBox(width: 12),

          // 설정 버튼
          _buildSettingsButton(),
          const SizedBox(width: 16),
        ],
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
          child: _isInitializing
              ? _buildLoadingIndicator()
              : _buildContent(),
        ),
      ),
      floatingActionButton: _isInitializing
          ? null
          : FloatingActionButton.extended(
              onPressed: _navigateToProfileInput,
              backgroundColor: const Color(0xFFE89BB5),
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                '새 프로필',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD4D4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFE89BB5),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              '준비 중...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8B3A62),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: _profiles.isEmpty
              ? _buildEmptyState()
              : _buildProfileList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '저장된',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 32,
              height: 1.2,
              fontWeight: FontWeight.w300,
              color: const Color(0xFF8B3A62).withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFE89BB5), Color(0xFF8B3A62)],
            ).createShader(bounds),
            child: const Text(
              '프로필 목록',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 32,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '프로필을 선택하거나 새로 추가해보세요',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: const Color(0xFF8B3A62).withOpacity(0.6),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE4E1).withOpacity(0.5),
              ),
              child: const Icon(
                Icons.person_add_outlined,
                size: 64,
                color: Color(0xFFE89BB5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '아직 프로필이 없어요',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8B3A62).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '새 프로필을 추가하고\n완벽한 답장을 받아보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: const Color(0xFF8B3A62).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        return _buildProfileCard(profile);
      },
    );
  }

  Widget _buildProfileCard(Profile profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToImageSelection(profile),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD4D4), Color(0xFFFFE4E1)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      profile.name[0],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B3A62),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A2842),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.age}세 • ${profile.gender}',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF8B3A62).withOpacity(0.6),
                        ),
                      ),
                      if (profile.memo != null && profile.memo!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          profile.memo!,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF8B3A62).withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteProfile(profile),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFE89BB5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
