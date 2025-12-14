import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/user_session.dart';
import '../services/api_client.dart';
import '../services/ocr_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late final OcrService _ocrService;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isInitializing = true;
  bool _isLoading = false;
  UserSession? _session;
  List<String> _suggestions = [];
  File? _selectedImage;
  late AnimationController _suggestionAnimationController;
  late AnimationController _pulseController;

  String? get _userId => _session?.userId;
  bool get _isPremium => _session?.isPremium ?? false;

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
    _suggestionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _initUser();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _suggestionAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _suggestions = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('user_id');
    final savedPremium = prefs.getBool('is_premium') ?? false;

    if (savedUserId != null) {
      setState(() {
        _session = UserSession(
          userId: savedUserId,
          isPremium: savedPremium,
        );
        _isInitializing = false;
      });
      return;
    }

    try {
      final newSession = await _apiClient.anonymousLogin();

      await prefs.setString('user_id', newSession.userId);
      await prefs.setBool('is_premium', newSession.isPremium);

      setState(() {
        _session = newSession;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('익명 로그인 실패: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _generateSuggestions() async {
    if (_selectedImage == null) {
      _showSnackBar('이미지를 먼저 선택해줘!', isError: true);
      return;
    }

    if (_userId == null) {
      _showSnackBar('로그인 정보를 불러오지 못했어. 다시 시도해줘!', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestions = [];
    });

    try {
      // Step 1: Extract text via OCR
      final extractedText = await _ocrService.extractTextFromImage(
        _selectedImage!.path,
      );

      // Step 2: Generate suggestions
      final res = await _apiClient.generateRizz(
        conversation: extractedText,
        userId: _userId!,
      );

      setState(() {
        _suggestions = res.suggestions;
      });

      // Trigger animation
      _suggestionAnimationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('처리 중 오류: $e', isError: true);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
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

  Future<void> _copyToClipboard(String text, int index) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('클립보드에 복사했어!');
  }

  Future<void> _refreshSubscription() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('user_id가 없어요. 다시 시도해줘!')),
      );
      return;
    }

    try {
      final session = await _apiClient.fetchSubscription(_userId!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', session.isPremium);

      setState(() {
        _session = session;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session.isPremium
                ? '프리미엄 구독 상태입니다 ✨'
                : '프리미엄이 아닌 상태입니다.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구독 조회 중 오류: $e')),
      );
    }
  }

  Future<void> _subscribeMonthly() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('user_id가 없어요. 다시 시도해줘!')),
      );
      return;
    }

    try {
      await _apiClient.subscribeMonthly(_userId!);
      await _refreshSubscription();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구독 신청 중 오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isInitializing || _isLoading;

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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isInitializing) _buildLoadingIndicator(),
                      const SizedBox(height: 16),
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildImagePreview(),
                      const SizedBox(height: 16),
                      _buildImageSelectionButtons(),
                      const SizedBox(height: 24),
                      _buildGenerateButton(isBusy),
                      const SizedBox(height: 32),
                      _buildSuggestionsSection(),
                    ],
                  ),
                ),
              ),
              _buildDebugPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD4D4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFE89BB5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '준비 중...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B3A62),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '마음을 전할',
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
            '완벽한 문장을',
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
          '대화 스크린샷을 보내주면, AI가 상황에 맞는\n완벽한 답장을 제안해드려요',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: const Color(0xFF8B3A62).withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: _selectedImage != null ? 280 : 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: _selectedImage != null
            ? [
                BoxShadow(
                  color: const Color(0xFFE89BB5).withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFD4D4),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                        _suggestions = [];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF8B3A62),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFD4D4),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.1),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(
                                    const Color(0xFFFFE4E1),
                                    const Color(0xFFFFD4D4),
                                    _pulseController.value,
                                  )!,
                                  const Color(0xFFFFE4E1),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: Color(0xFFE89BB5),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '채팅 스크린샷을 추가해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8B3A62),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '갤러리나 카메라로 선택할 수 있어요',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF8B3A62).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSelectionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildImageButton(
            icon: Icons.photo_library_outlined,
            label: '갤러리',
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildImageButton(
            icon: Icons.camera_alt_outlined,
            label: '카메라',
            onPressed: () => _pickImage(ImageSource.camera),
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD4D4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF8B3A62)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8B3A62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(bool isBusy) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : _generateSuggestions,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            gradient: isBusy
                ? LinearGradient(
                    colors: [
                      const Color(0xFFD4A5A5).withOpacity(0.5),
                      const Color(0xFFE89BB5).withOpacity(0.5),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFB5B5),
                      Color(0xFFE89BB5),
                      Color(0xFFD4A5A5),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isBusy
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFFE89BB5).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: _isInitializing
                ? const Text(
                    '준비 중...',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  )
                : _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '✨ 완벽한 답장 받기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    if (_suggestions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '추천 문장',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8B3A62).withOpacity(0.9),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        ..._suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;
          return _buildSuggestionCard(suggestion, index);
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFE4E1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFE4E1).withOpacity(0.5),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Color(0xFFE89BB5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '아직 추천이 없어요',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8B3A62).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '스크린샷을 추가하고\n버튼을 눌러보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFF8B3A62).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String suggestion, int index) {
    return AnimatedBuilder(
      animation: _suggestionAnimationController,
      builder: (context, child) {
        final delay = index * 0.15;
        final adjustedValue = (_suggestionAnimationController.value - delay).clamp(0.0, 1.0);
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
        margin: const EdgeInsets.only(bottom: 12),
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
            onTap: () => _copyToClipboard(suggestion, index),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD4D4), Color(0xFFFFE4E1)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B3A62),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF5A2842),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E1).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.content_copy,
                      size: 18,
                      color: Color(0xFFE89BB5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD4D4).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '개발자 도구',
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF8B3A62).withOpacity(0.4),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDebugButton(
                  '구독 확인',
                  _refreshSubscription,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDebugButton(
                  '프리미엄 등록',
                  _subscribeMonthly,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebugButton(String label, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFFFD4D4).withOpacity(0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF8B3A62).withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}