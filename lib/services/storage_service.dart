import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';

/// 프로필 데이터를 로컬에 저장/조회하는 서비스
class StorageService {
  static const String _profilesKey = 'profiles';

  /// 모든 프로필 조회
  Future<List<Profile>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString(_profilesKey);

    if (profilesJson == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(profilesJson);
    return decoded.map((json) => Profile.fromJson(json)).toList();
  }

  /// 프로필 저장
  Future<void> saveProfile(Profile profile) async {
    final profiles = await getProfiles();
    profiles.add(profile);
    await _saveProfiles(profiles);
  }

  /// 프로필 업데이트
  Future<void> updateProfile(Profile profile) async {
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);

    if (index != -1) {
      profiles[index] = profile;
      await _saveProfiles(profiles);
    }
  }

  /// 프로필 삭제
  Future<void> deleteProfile(String profileId) async {
    final profiles = await getProfiles();
    profiles.removeWhere((p) => p.id == profileId);
    await _saveProfiles(profiles);
  }

  /// 특정 프로필 조회
  Future<Profile?> getProfile(String profileId) async {
    final profiles = await getProfiles();
    try {
      return profiles.firstWhere((p) => p.id == profileId);
    } catch (e) {
      return null;
    }
  }

  /// 프로필 목록 저장 (내부 헬퍼 메서드)
  Future<void> _saveProfiles(List<Profile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = jsonEncode(
      profiles.map((p) => p.toJson()).toList(),
    );
    await prefs.setString(_profilesKey, profilesJson);
  }
}
