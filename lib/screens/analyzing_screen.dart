import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/api_client.dart';
import 'response_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  final String imagePath;
  final Profile profile;
  final String userId;
  final int usedCount;
  final int totalCount;
  final bool isPremium;

  const AnalyzingScreen({
    super.key,
    required this.imagePath,
    required this.profile,
    required this.userId,
    required this.usedCount,
    required this.totalCount,
    required this.isPremium,
  });

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late AnimationController _scannerController;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _startAnalysis();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    try {
      // 백엔드로 이미지 전송하여 OCR + 추천 생성
      // 프로필 정보를 기반으로 개인화된 답장 생성
      final response = await _apiClient.analyzeImage(
        imagePath: widget.imagePath,
        userId: widget.userId,
        profileId: widget.profile.id,
        numSuggestions: 3,
      );

      if (!mounted) return;

      // 추천 답변 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResponseScreen(
            profile: widget.profile,
            response: response,
            usedCount: widget.usedCount + 1,
            totalCount: widget.totalCount,
            isPremium: widget.isPremium,
            userId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
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
          child: _hasError ? _buildErrorState() : _buildAnalyzingState(),
        ),
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 스캐너 애니메이션
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 외부 링
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE89BB5).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  // 중간 링
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE89BB5).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                  // 내부 아이콘
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFB5B5).withOpacity(0.3),
                          const Color(0xFFE89BB5).withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: Color(0xFFE89BB5),
                    ),
                  ),
                  // 스캐닝 라인 (위아래로 움직임)
                  AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (_scannerController.value * 200),
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFFE89BB5).withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE89BB5).withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // 분석 중 텍스트
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFE89BB5), Color(0xFF8B3A62)],
              ).createShader(bounds),
              child: const Text(
                '대화 분석 중...',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI가 대화를 분석하고\n완벽한 답장을 준비하고 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: const Color(0xFF8B3A62).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            // 로딩 인디케이터
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFE89BB5).withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
                Icons.error_outline,
                size: 64,
                color: Color(0xFF8B3A62),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '분석 실패',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B3A62),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '알 수 없는 오류가 발생했어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: const Color(0xFF8B3A62).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 48),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFB5B5),
                        Color(0xFFE89BB5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '돌아가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
