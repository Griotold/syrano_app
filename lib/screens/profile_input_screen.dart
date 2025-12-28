import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/api_client.dart';

class ProfileInputScreen extends StatefulWidget {
  final String userId;

  const ProfileInputScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileInputScreen> createState() => _ProfileInputScreenState();
}

class _ProfileInputScreenState extends State<ProfileInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _memoController = TextEditingController();

  String _selectedGender = '여성';

  final List<String> _genderList = ['남성', '여성', '기타'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // API로 프로필 생성
      await _apiClient.createProfile(
        userId: widget.userId,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필 저장 실패: $e'),
          backgroundColor: const Color(0xFF8B3A62),
        ),
      );
    }
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
        title: const Text(
          '새 프로필',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8B3A62),
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _nameController,
                  label: '이름',
                  hint: '상대방의 이름을 입력하세요',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _ageController,
                  label: '나이',
                  hint: '나이를 입력하세요',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '나이를 입력해주세요';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 150) {
                      return '올바른 나이를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildDropdown(
                  label: '성별',
                  value: _selectedGender,
                  items: _genderList,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _memoController,
                  label: '메모 (선택)',
                  hint: 'MBTI, 취미, 특징 등을 자유롭게 적어주세요\n예: ENFP, 영화 좋아함, 고양이 키움',
                  maxLines: 4,
                  maxLength: 50,
                ),
                const SizedBox(height: 40),
                _buildSaveButton(),
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
          '프로필',
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
            '정보 입력',
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
          '상대방에 대한 정보를 입력해주세요',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF8B3A62).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int? maxLines,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B3A62),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            counterText: maxLength != null ? null : '',
            hintStyle: TextStyle(
              color: const Color(0xFF8B3A62).withOpacity(0.3),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFFFD4D4),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFFFD4D4),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE89BB5),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF8B3A62),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF8B3A62),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B3A62),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD4D4),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE89BB5)),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5A2842),
              ),
              dropdownColor: const Color(0xFFFFF8F3),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saveProfile,
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
              '저장하기',
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
