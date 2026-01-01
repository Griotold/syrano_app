import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile.dart';
import '../widgets/usage_badge.dart';
import '../widgets/usage_dialog.dart';
import 'analyzing_screen.dart';

class ImageSelectionScreen extends StatefulWidget {
  final Profile profile;
  final String userId;
  final int usedCount;
  final int totalCount;
  final bool isPremium;

  const ImageSelectionScreen({
    super.key,
    required this.profile,
    required this.userId,
    required this.usedCount,
    required this.totalCount,
    required this.isPremium,
  });

  @override
  State<ImageSelectionScreen> createState() => _ImageSelectionScreenState();
}

class _ImageSelectionScreenState extends State<ImageSelectionScreen>
    with TickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
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
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지를 먼저 선택해주세요!'),
          backgroundColor: Color(0xFF8B3A62),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyzingScreen(
          imagePath: _selectedImage!.path,
          profile: widget.profile,
          userId: widget.userId,
          usedCount: widget.usedCount,
          totalCount: widget.totalCount,
          isPremium: widget.isPremium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B3A62)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.profile.name,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8B3A62),
          ),
        ),
        actions: [
          UsageBadge(
            usedCount: widget.usedCount,
            totalCount: widget.totalCount,
            isPremium: widget.isPremium,
            onTap: () => showUsageDialog(
              context,
              isPremium: widget.isPremium,
              usedCount: widget.usedCount,
              totalCount: widget.totalCount,
              userId: widget.userId,
            ),
          ),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildImagePreview(),
                const SizedBox(height: 16),
                _buildGalleryButton(),
                const SizedBox(height: 16),
                const Spacer(),
                _buildAnalyzeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '대화 스크린샷을',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w300,
            color: const Color(0xFF8B3A62).withOpacity(0.9),
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE89BB5), Color(0xFF8B3A62)],
          ).createShader(bounds),
          child: const Text(
            '선택해주세요',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '갤러리에서 채팅 스크린샷을 선택하세요',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF8B3A62).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 360,
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
                      height: double.infinity,
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
          : GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFFD4D4),
                    width: 2,
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
                        '갤러리에서 선택할 수 있어요',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF8B3A62).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGalleryButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 3,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _pickImage(ImageSource.gallery),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 56,
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
                  Icon(
                    Icons.photo_library_outlined,
                    size: 20,
                    color: const Color(0xFF8B3A62),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '갤러리',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8B3A62),
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

  Widget _buildAnalyzeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _analyzeImage,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFB5B5),
                Color(0xFFE89BB5),
                Color(0xFFD4A5A5),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE89BB5).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '분석 시작하기',
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
}
