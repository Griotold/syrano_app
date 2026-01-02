import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_session.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _userId;
  UserSession? _session;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final isPremium = prefs.getBool('is_premium') ?? false;

    setState(() {
      _userId = userId;
      if (userId != null) {
        _session = UserSession(userId: userId, isPremium: isPremium);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC8879E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 1. 계정 정보 섹션
                _buildSectionHeader('계정 정보'),
                _buildUserIdTile(),

                // 2. 구독 정보 섹션 (프리미엄만)
                if (_session?.isPremium == true) ...[
                  _buildSectionHeader('구독 정보'),
                  _buildSubscriptionTile(),
                ],

                // 3. 지원 섹션
                _buildSectionHeader('지원'),
                _buildContactTile(),

                // 4. 앱 정보 섹션
                _buildSectionHeader('앱 정보'),
                _buildVersionTile(),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8B3A62).withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // 1. 사용자 ID 타일
  Widget _buildUserIdTile() {
    return _buildTile(
      icon: Icons.fingerprint,
      title: '사용자 ID',
      subtitle: _userId ?? '로드 중...',
      trailing: IconButton(
        icon: const Icon(Icons.copy, color: Color(0xFF8B3A62)),
        onPressed: _copyUserId,
        tooltip: '복사',
      ),
    );
  }

  void _copyUserId() {
    if (_userId != null) {
      Clipboard.setData(ClipboardData(text: _userId!));
      _showSnackBar('사용자 ID가 복사되었습니다');
    }
  }

  Future<void> _openSubscriptionManagement() async {
    try {
      final Uri url;

      if (Platform.isIOS) {
        // iOS: App Store 구독 관리
        url = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else {
        // Android: Play Store 구독 관리
        url = Uri.parse('https://play.google.com/store/account/subscriptions');
      }

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;
        _showSnackBar(
          '구독 관리 화면을 열 수 없습니다. 설정 앱에서 직접 확인해주세요.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        '오류가 발생했습니다: $e',
        isError: true,
      );
    }
  }

  // 2. 구독 정보 타일
  Widget _buildSubscriptionTile() {
    return _buildTile(
      icon: Icons.workspace_premium,
      iconColor: const Color(0xFFFFD700),
      title: '프리미엄 구독',
      subtitle: '월간 플랜 • 활성화',
      onTap: _openSubscriptionManagement,
    );
  }

  // 3. 문의하기 타일
  Widget _buildContactTile() {
    return _buildTile(
      icon: Icons.email_outlined,
      title: '문의하기',
      subtitle: 'support@syrano.app',
      onTap: _contactSupport,
    );
  }

  Future<void> _contactSupport() async {
    final email = Uri(
      scheme: 'mailto',
      path: 'support@syrano.app',
      queryParameters: {
        'subject': 'Syrano 문의',
        'body': '''
안녕하세요,

문의 내용을 작성해주세요.

---
[자동 생성 정보]
사용자 ID: $_userId
앱 버전: 1.0.0
플랫폼: ${Platform.isIOS ? 'iOS' : 'Android'}
날짜: ${DateTime.now().toString().split('.')[0]}
        ''',
      },
    );

    try {
      if (await canLaunchUrl(email)) {
        await launchUrl(email);
      } else {
        if (!mounted) return;
        _showSnackBar('이메일 앱을 열 수 없습니다', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('오류가 발생했습니다: $e', isError: true);
    }
  }

  // 4. 앱 버전 타일
  Widget _buildVersionTile() {
    return _buildTile(
      icon: Icons.info_outline,
      title: '앱 버전',
      subtitle: '1.0.0',
    );
  }

  // 공통 타일 위젯
  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD4D4),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? const Color(0xFF8B3A62),
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B3A62),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF8B3A62).withOpacity(0.6),
                ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFFFD4D4),
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFF8B3A62) : const Color(0xFFD4A5A5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
