# TODO - Syrano Flutter App

## 📊 Progress Summary

**Phase 1 (MVP):** ✅ **완료** (2025-12-28)  
- 익명 인증 시스템
- 로컬 프로필 관리
- 이미지 기반 OCR + AI 메시지 생성
- 기본 UI/UX

**Phase 2 (백엔드 연동):** 🔴 **진행 중**  
**Phase 3 (디자인 개선):** ⏸️ **대기**  
**Phase 4 (확장 기능):** ⏸️ **대기**

---

## 🔴 High Priority (Phase 2 - 백엔드 Profile API 연동)

### 1. Profile API 클라이언트 구현
**상태:** 🔴 **미작업**

**작업 내용:**

```dart
// lib/services/api_client.dart에 추가

/// POST /profiles - 프로필 생성
Future<Profile> createProfile({
  required String userId,
  required String name,
  required int age,
  required String gender,
  String? memo,
}) async {
  final url = _uri('/profiles');
  
  final response = await _client.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'user_id': userId,
      'name': name,
      'age': age,
      'gender': gender,
      'memo': memo,
    }),
  );
  
  if (response.statusCode != 200) {
    throw Exception('createProfile failed: ${response.statusCode}');
  }
  
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return Profile.fromJson(data);
}

/// GET /profiles?user_id=xxx - 프로필 목록 조회
Future<List<Profile>> getProfiles(String userId) async {
  final url = _uri('/profiles', query: {'user_id': userId});
  
  final response = await _client.get(url);
  
  if (response.statusCode != 200) {
    throw Exception('getProfiles failed: ${response.statusCode}');
  }
  
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final profilesJson = data['profiles'] as List;
  return profilesJson.map((json) => Profile.fromJson(json)).toList();
}

/// DELETE /profiles/{profile_id} - 프로필 삭제
Future<void> deleteProfile(String profileId) async {
  final url = _uri('/profiles/$profileId');
  
  final response = await _client.delete(url);
  
  if (response.statusCode != 204) {
    throw Exception('deleteProfile failed: ${response.statusCode}');
  }
}
```

**예상 시간:** 1시간

---

### 2. Profile 모델 수정 (백엔드 스키마 맞추기)
**상태:** 🔴 **미작업**

**현재 플러터 Profile 구조:**

```dart
// lib/models/profile.dart (현재)
class Profile {
  final String id;          // ❌ 로컬 타임스탬프 ID
  final String name;
  final int age;
  final String mbti;        // ❌ 백엔드에 없음 - 제거 필요
  final String gender;
  final String? memo;
  final DateTime createdAt; // ❌ 로컬 생성 시각
}
```

**백엔드 Profile 스키마 (✅ 이미 완료됨):**

```python
# app/models/profile.py
class Profile(Base):
    id = Column(String(36), primary_key=True)  # UUID
    user_id = Column(String(36), ForeignKey('users.id'))
    name = Column(String(100), nullable=False)
    age = Column(Integer, nullable=True)
    gender = Column(String(10), nullable=True)
    memo = Column(Text, nullable=True)  # ✅ MBTI 정보는 여기 텍스트로 저장
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
```

**수정해야 할 플러터 모델:**

```dart
// lib/models/profile.dart (수정 후)
class Profile {
  final String id;          // ✅ 백엔드 UUID (서버 생성)
  final String userId;      // ✅ 추가
  final String name;
  final int age;
  final String gender;
  final String? memo;       // ✅ MBTI는 여기 텍스트로 포함 (예: "ENFP, 영화 좋아함")
  final DateTime createdAt; // ✅ 서버 생성 시각
  final DateTime updatedAt; // ✅ 추가
  
  // ❌ Profile.create() 팩토리 제거 (서버에서 ID 생성)
  
  // JSON 역직렬화 수정
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      userId: json['user_id'] as String,  // ✅ 추가
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),  // ✅ 추가
    );
  }
}
```

**UI 수정 필요:**

```dart
// lib/screens/profile_input_screen.dart
// MBTI 드롭다운 제거 → memo 입력에 통합

// 기존
_buildDropdown(label: 'MBTI', value: _selectedMbti, ...)
_buildTextField(label: '메모 (선택)', ...)

// 수정 후
_buildTextField(
  label: '메모 (선택)',
  hint: 'MBTI, 취미, 특징 등을 자유롭게 적어주세요',
  controller: _memoController,
)
```

**예상 시간:** 1시간 (모델 수정 + UI 수정)

---

### 3. ProfileInputScreen 수정 (API 호출 + MBTI 제거)
**상태:** 🔴 **미작업**

**현재 로직:**

```dart
// lib/screens/profile_input_screen.dart:_saveProfile()
final profile = Profile.create(  // ❌ 로컬 생성
  name: _nameController.text.trim(),
  age: int.parse(_ageController.text.trim()),
  mbti: _selectedMbti,  // ❌ 백엔드에 없음
  gender: _selectedGender,
  memo: _memoController.text.trim(),
);

await _storageService.saveProfile(profile);  // ❌ 로컬 저장
```

**개선 로직:**

```dart
// lib/screens/profile_input_screen.dart:_saveProfile()
final profile = await _apiClient.createProfile(  // ✅ API 호출
  userId: widget.userId,  // ✅ 추가 필요
  name: _nameController.text.trim(),
  age: int.parse(_ageController.text.trim()),
  gender: _selectedGender,
  memo: _memoController.text.trim(),  // ✅ MBTI 포함 가능
);

// ✅ 로컬 저장은 제거 (백엔드가 단일 진실 공급원)
Navigator.pop(context, true);
```

**UI 변경:**

```dart
// MBTI 드롭다운 제거
// 기존 (_selectedMbti, _mbtiList, _buildDropdown)

// memo 입력 필드 안내 개선
_buildTextField(
  controller: _memoController,
  label: '메모 (선택)',
  hint: 'MBTI, 취미, 특징 등을 자유롭게 적어주세요\n예: ENFP, 영화 좋아함, 고양이 키움',
  maxLines: 3,
)
```

**필요한 변경:**

1. `ProfileInputScreen`에 `userId` 파라미터 추가

```dart
class ProfileInputScreen extends StatefulWidget {
  final String userId;  // ✅ 추가
  
  const ProfileInputScreen({
    super.key,
    required this.userId,
  });
}
```

2. HomeScreen에서 userId 전달

```dart
// lib/screens/home_screen.dart
Future<void> _navigateToProfileInput() async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => ProfileInputScreen(
        userId: _userId!,  // ✅ 전달
      ),
    ),
  );
}
```

**예상 시간:** 1시간

---

### 4. HomeScreen 수정 (API 조회 & 삭제)
**상태:** 🔴 **미작업**

**현재 로직:**

```dart
// lib/screens/home_screen.dart
Future<void> _loadProfiles() async {
  final profiles = await _storageService.getProfiles();  // ❌ 로컬 조회
  setState(() {
    _profiles = profiles;
  });
}

Future<void> _deleteProfile(Profile profile) async {
  await _storageService.deleteProfile(profile.id);  // ❌ 로컬 삭제
  await _loadProfiles();
}
```

**개선 로직:**

```dart
// lib/screens/home_screen.dart
Future<void> _loadProfiles() async {
  if (_userId == null) return;
  
  final profiles = await _apiClient.getProfiles(_userId!);  // ✅ API 조회
  setState(() {
    _profiles = profiles;
  });
}

Future<void> _deleteProfile(Profile profile) async {
  await _apiClient.deleteProfile(profile.id);  // ✅ API 삭제
  await _loadProfiles();
  _showSnackBar('프로필이 삭제되었어요');
}
```

**예상 시간:** 30분

---

### 5. analyze-image API에 profile_id 추가
**상태:** 🔴 **미작업**

**현재 API 호출:**

```dart
// lib/services/api_client.dart:analyzeImage()
Future<RizzResponse> analyzeImage({
  required String imagePath,
  required String userId,
  String platform = 'kakao',        // ❌ 제거 예정
  String relationship = 'first_meet', // ❌ 제거 예정
  String style = 'banmal',           // ❌ 제거 예정
  String tone = 'friendly',          // ❌ 제거 예정
  int numSuggestions = 3,
}) async {
  // ...
  request.fields['platform'] = platform;
  request.fields['relationship'] = relationship;
  request.fields['style'] = style;
  request.fields['tone'] = tone;
}
```

**개선 API 호출:**

```dart
// lib/services/api_client.dart:analyzeImage()
Future<RizzResponse> analyzeImage({
  required String imagePath,
  required String userId,
  required String profileId,  // ✅ 추가
  int numSuggestions = 3,
}) async {
  // ...
  request.fields['user_id'] = userId;
  request.fields['profile_id'] = profileId;  // ✅ 추가
  request.fields['num_suggestions'] = numSuggestions.toString();
  
  // ✅ platform, relationship, style, tone 제거
  // 백엔드에서 profile_id로 프로필 조회 후 자동 판단
}
```

**예상 시간:** 30분

---

## 🟡 Medium Priority (Phase 2 완료 후)

### 7. 사용량 제한 UI 추가
**상태:** ⏸️ **대기**

**백엔드 API:**

```python
# 현재 백엔드는 사용량 제한 구현됨
# - 무료: 5회/일
# - 프리미엄: 무제한
# - 응답에 usage_info 포함

{
  "suggestions": [...],
  "usage_info": {
    "remaining": 4,
    "limit": 5,
    "is_premium": false
  }
}
```

**플러터 구현:**

1. **RizzResponse 모델 수정**

```dart
// lib/models/rizz_response.dart
class RizzResponse {
  final List<String> suggestions;
  final UsageInfo usageInfo;  // ✅ 추가
  
  factory RizzResponse.fromJson(Map<String, dynamic> json) {
    return RizzResponse(
      suggestions: (json['suggestions'] as List).map((e) => e.toString()).toList(),
      usageInfo: UsageInfo.fromJson(json['usage_info']),
    );
  }
}

class UsageInfo {
  final int remaining;  // -1: 무제한
  final int limit;      // -1: 무제한
  final bool isPremium;
  
  factory UsageInfo.fromJson(Map<String, dynamic> json) {
    return UsageInfo(
      remaining: json['remaining'],
      limit: json['limit'],
      isPremium: json['is_premium'],
    );
  }
}
```

2. **HomeScreen에 사용량 표시**

```dart
// lib/screens/home_screen.dart
Widget _buildUsageInfo() {
  if (_isPremium) {
    return Text('무제한 사용 가능 ✨');
  }
  
  return Row([
    Icon(Icons.pending_outlined),
    Text('오늘 ${_usageInfo.remaining}/${_usageInfo.limit}회 남음'),
  ]);
}
```

3. **사용량 초과 시 에러 처리**

```dart
// lib/screens/analyzing_screen.dart
try {
  final response = await _apiClient.analyzeImage(...);
} catch (e) {
  if (e.toString().contains('429')) {
    // 사용량 초과
    setState(() {
      _errorMessage = '오늘 무료 사용 횟수를 모두 사용했어요.\n프리미엄으로 업그레이드하시겠어요?';
    });
  }
}
```

**예상 시간:** 2시간

---

### 8. 에러 핸들링 개선
**상태:** ⏸️ **대기**

**현재 문제:**

```dart
// lib/screens/analyzing_screen.dart
catch (e) {
  setState(() {
    _errorMessage = e.toString();  // ❌ 사용자에게 친절하지 않음
  });
}
```

**개선 방향:**

```dart
// lib/services/api_client.dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? userMessage;
  
  ApiException(this.statusCode, this.message, {this.userMessage});
  
  factory ApiException.fromResponse(http.Response response) {
    if (response.statusCode == 429) {
      return ApiException(
        429,
        'Rate limit exceeded',
        userMessage: '오늘 무료 사용 횟수를 모두 사용했어요',
      );
    }
    // ...
  }
}

// 사용
try {
  final response = await _apiClient.analyzeImage(...);
} catch (e) {
  if (e is ApiException) {
    setState(() {
      _errorMessage = e.userMessage ?? '알 수 없는 오류가 발생했어요';
    });
  }
}
```

**에러별 메시지:**

| Status Code | 사용자 메시지 |
|-------------|---------------|
| 400 | 잘못된 요청이에요. 다시 시도해주세요. |
| 401 | 로그인이 필요해요. |
| 404 | 프로필을 찾을 수 없어요. |
| 429 | 오늘 무료 사용 횟수를 모두 사용했어요. |
| 500 | 서버 오류가 발생했어요. 잠시 후 다시 시도해주세요. |
| Timeout | 네트워크 연결이 느려요. 다시 시도해주세요. |

**예상 시간:** 2시간

---

### 9. 이미지 최적화
**상태:** ⏸️ **대기**

**현재 문제:**  
큰 이미지를 그대로 업로드 → 느린 업로드 속도

**개선 방향:**

1. **이미지 압축 패키지 추가**

```yaml
# pubspec.yaml
dependencies:
  image: ^4.0.0  # 이미지 리사이징/압축
```

2. **이미지 최적화 함수**

```dart
// lib/services/image_optimizer.dart
import 'dart:io';
import 'package:image/image.dart' as img;

class ImageOptimizer {
  static Future<File> optimizeImage(String imagePath) async {
    // 1. 이미지 로드
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) throw Exception('이미지를 읽을 수 없어요');
    
    // 2. 리사이징 (최대 1024px)
    final resized = img.copyResize(
      image,
      width: image.width > 1024 ? 1024 : null,
    );
    
    // 3. JPEG 압축 (85% 품질)
    final compressed = img.encodeJpg(resized, quality: 85);
    
    // 4. 임시 파일 저장
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/optimized.jpg');
    await tempFile.writeAsBytes(compressed);
    
    return tempFile;
  }
}
```

3. **ImageSelectionScreen에서 사용**

```dart
// lib/screens/image_selection_screen.dart
Future<void> _analyzeImage() async {
  // 이미지 최적화
  final optimizedImage = await ImageOptimizer.optimizeImage(
    _selectedImage!.path,
  );
  
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AnalyzingScreen(
        imagePath: optimizedImage.path,  // ✅ 최적화된 이미지
        profile: widget.profile,
        userId: widget.userId,
      ),
    ),
  );
}
```

**예상 시간:** 2시간

---

## 🟢 Low Priority (Phase 3 이후)

### 10. 디자인 개선 (frontend-design 스킬 활용)
**상태:** ⏸️ **대기**

**개선 방향:**
- 온보딩 화면
- 스플래시 화면
- 빈 상태 디자인 개선
- Micro-interactions
- 다크 모드 지원

**예상 시간:** 8시간

---

### 11. 히스토리 기능
**상태:** ⏸️ **대기**

**기능:**
- 과거 생성한 답장 저장
- 히스토리 화면 추가
- 즐겨찾기 기능

**예상 시간:** 6시간

---

### 12. 실제 결제 연동
**상태:** ⏸️ **대기**

**기능:**
- In-App Purchase (iOS/Android)
- 영수증 검증
- 구독 복원

**예상 시간:** 12시간

---

## 📊 Progress Tracker

### Phase 1 (MVP) ✅
- [x] 익명 인증 시스템
- [x] 로컬 프로필 관리
- [x] 이미지 선택 (갤러리/카메라)
- [x] 백엔드 OCR API 연동
- [x] 추천 답변 표시
- [x] 클립보드 복사
- [x] 기본 UI/UX

### Phase 2 (백엔드 Profile API 연동) 🔴
- [ ] Profile API 클라이언트 구현 (1시간)
- [ ] Profile 모델 수정 - MBTI 제거 (1시간)
- [ ] ProfileInputScreen 수정 (1시간)
- [ ] HomeScreen 수정 (30분)
- [ ] analyze-image에 profile_id 추가 (30분)

**총 예상 시간:** 4시간 (플러터만)

**참고:** 백엔드는 이미 완료됨 (2025-12-27)
- ✅ Profile CRUD API (`/profiles`)
- ✅ `analyze-image` API가 `profile_id` 지원
- ✅ 프로필 정보 기반 프롬프트 개선

### Phase 2 추가 작업 🟡
- [ ] 사용량 제한 UI (2시간)
- [ ] 에러 핸들링 개선 (2시간)
- [ ] 이미지 최적화 (2시간)

**총 예상 시간:** 6시간

### Phase 3 (디자인 개선) ⏸️
- [ ] 온보딩/스플래시 화면
- [ ] Micro-interactions
- [ ] 다크 모드

### Phase 4 (확장 기능) ⏸️
- [ ] 히스토리 기능
- [ ] 실제 결제 연동

---

## 🎯 Next Sprint (우선 작업)

**이번 주 목표:** Phase 2 완료 (플러터 → 백엔드 API 연동)

**백엔드 상태:** ✅ **이미 완료됨** (2025-12-27)
- ✅ Profile CRUD API 구현
- ✅ `analyze-image`가 `profile_id` 지원
- ✅ 프로필 정보 기반 프롬프트

**플러터 작업 목록:**

1. 🔴 **Profile API 클라이언트 구현** (1시간)
2. 🔴 **Profile 모델 수정 - MBTI 제거** (1시간)
3. 🔴 **ProfileInputScreen 수정** (1시간)
4. 🔴 **HomeScreen 수정** (30분)
5. 🔴 **analyze-image에 profile_id 추가** (30분)

**총 예상 시간:** 4시간

**완료 기준:**
- ✅ 플러터 Profile 모델이 백엔드 스키마와 일치 (MBTI 제거)
- ✅ 프로필이 백엔드 API로 생성/조회/삭제됨
- ✅ 로컬 StorageService 제거 완료
- ✅ `analyzeImage()`가 `profile_id`를 백엔드로 전달
- ✅ 프로필 정보가 LLM 추천에 반영됨 (백엔드에서 처리)

---

## 📝 Notes

### 백엔드 상태 (2025-12-27 완료)
- ✅ **Profile CRUD API 완료**
  - `POST /profiles` - 프로필 생성
  - `GET /profiles?user_id=xxx` - 프로필 목록
  - `GET /profiles/{id}` - 프로필 조회
  - `PUT /profiles/{id}` - 프로필 수정
  - `DELETE /profiles/{id}` - 프로필 삭제

- ✅ **analyze-image API 개선 완료**
  - `profile_id` 파라미터 지원
  - 프로필 정보 기반 프롬프트 생성
  - `platform`, `relationship`, `style`, `tone` 제거

- ✅ **사용량 제한 구현 완료**
  - 무료: 5회/일
  - 프리미엄: 무제한
  - 응답에 `usage_info` 포함

### 플러터 현재 상태 (2025-12-28)
- ✅ 기본 기능은 모두 작동함
- ✅ OCR + AI 메시지 생성 가능
- ⚠️ 프로필이 로컬에만 저장됨 (백엔드 미연동)
- ⚠️ Profile 모델에 MBTI 필드 있음 (백엔드에는 없음)
- ⚠️ `analyzeImage()`가 `profile_id` 대신 `platform`, `relationship` 등 전달

### Phase 2의 중요성
**왜 Profile API 연동이 중요한가?**

1. **데이터 영구성**
   - 앱 삭제 시에도 프로필 유지
   - 여러 기기에서 동기화 가능

2. **AI 품질 개선**
   - 백엔드 프롬프트에서 프로필 정보 활용
   - 상대방에게 맞춤화된 답장 생성
   - 이름, 나이, 성별, 메모를 고려한 개인화

3. **확장성**
   - 프로필 기반 통계 수집
   - 사용 패턴 분석
   - 프로필별 추천 품질 개선

---

**문서 버전:** 1.0  
**최종 수정일:** 2025-12-28  
**다음 업데이트:** Phase 2 완료 시