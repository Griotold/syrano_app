import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_session.dart';
import '../models/profile.dart';
import '../services/api_client.dart';
import 'profile_input_screen.dart';
import 'image_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _isInitializing = true;
  UserSession? _session;
  List<Profile> _profiles = [];

  String? get _userId => _session?.userId;
  bool get _isPremium => _session?.isPremium ?? false;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ 이 한 줄만 추가!
    await prefs.remove('profiles');
    
    final savedUserId = prefs.getString('user_id');
    final savedPremium = prefs.getBool('is_premium') ?? false;

    if (savedUserId != null) {
      setState(() {
        _session = UserSession(
          userId: savedUserId,
          isPremium: savedPremium,
        );
      });
    } else {
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

    // 프로필 목록 로드
    await _loadProfiles();

    setState(() {
      _isInitializing = false;
    });
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
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Syrano',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
            color: Color(0xFF8B3A62),
          ),
        ),
        actions: [
          if (_isPremium)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB5B5), Color(0xFFE89BB5)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE89BB5).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'PREMIUM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
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
