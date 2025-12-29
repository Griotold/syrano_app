# Syrano App (syrano_app)

Flutter mobile application for **Syrano**, a Korean dating chat assistant that generates attractive and context-aware chat messages using AI and OCR technology.

---

## 📦 Tech Stack

- **Framework:** Flutter 3.38.3
- **Language:** Dart 3.10.1
- **State Management:** StatefulWidget (기본)
- **Local Storage:** SharedPreferences
- **HTTP Client:** http ^1.2.1
- **Image Picker:** image_picker ^1.1.2
- **Backend:** DigitalOcean (https://syrano-be-sjtv2.ondigitalocean.app)

---

## 📁 Project Structure

```
syrano_app/
├── lib/
│   ├── main.dart                      # 앱 진입점
│   ├── models/                        # 데이터 모델
│   │   ├── profile.dart               # 프로필 모델 (로컬 저장)
│   │   ├── user_session.dart          # 사용자 세션 (user_id, is_premium)
│   │   └── rizz_response.dart         # AI 응답 모델
│   ├── screens/                       # 화면 컴포넌트
│   │   ├── home_screen.dart           # 홈 화면 (프로필 목록)
│   │   ├── profile_input_screen.dart  # 프로필 입력 화면
│   │   ├── image_selection_screen.dart # 이미지 선택 화면
│   │   ├── analyzing_screen.dart      # 분석 중 화면
│   │   └── response_screen.dart       # 추천 답변 화면
│   └── services/                      # 비즈니스 로직
│       ├── api_client.dart            # REST API 통신
│       └── storage_service.dart       # 로컬 프로필 CRUD
├── docs/
│   └── PRD.md                         # 제품 요구사항 문서
├── pubspec.yaml                       # 의존성 관리
└── README.md                          # 프로젝트 문서
```

---

## 🔧 Environment Setup

### Prerequisites
- Flutter SDK: ^3.10.1
- Dart SDK: ^3.10.1
- iOS Simulator / Android Emulator

### Installation

```bash
# 1. 저장소 클론
cd ~/Desktop/dev/syrano_app

# 2. 의존성 설치
flutter pub get

# 3. 시뮬레이터 실행 (iOS)
open -a Simulator

# 4. 앱 실행
flutter run
```

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.2.1                  # REST API 통신
  shared_preferences: ^2.3.2    # 로컬 저장소
  image_picker: ^1.1.2          # 이미지 선택
```

---

## 🌐 Backend Configuration

### API Base URL
```dart
// lib/services/api_client.dart
static const String _baseUrl = 'https://syrano-be-sjtv2.ondigitalocean.app';
```

Production 환경에서는 이 URL이 사용됩니다.  
로컬 개발 시 백엔드를 `localhost`로 변경 가능:

```dart
static const String _baseUrl = 'http://localhost:8000'; // 로컬 개발용
```

---

## 💬 Core Features

### 1. 익명 인증 시스템

**앱 최초 실행 시 자동 로그인**  
- `POST /auth/anonymous` → 새 `user_id` 생성
- SharedPreferences에 저장 → 앱 삭제 전까지 유지

```dart
// lib/screens/home_screen.dart:_initUser()
final newSession = await _apiClient.anonymousLogin();
await prefs.setString('user_id', newSession.userId);
await prefs.setBool('is_premium', newSession.isPremium);
```

**재방문 시**  
- SharedPreferences에서 `user_id` 로드
- 서버 호출 없이 즉시 사용

---

### 2. 프로필 관리 (로컬 저장)

**프로필 데이터 구조**

```dart
// lib/models/profile.dart
class Profile {
  final String id;          // 타임스탬프 기반 고유 ID
  final String name;        // 상대방 이름 (필수)
  final int age;            // 나이 (필수)
  final String mbti;        // MBTI (필수, 16가지)
  final String gender;      // 성별 (남성/여성/기타)
  final String? memo;       // 메모 (선택)
  final DateTime createdAt; // 생성 시각
}
```

**CRUD 기능**

| 기능 | 메서드 | 화면 |
|------|--------|------|
| 생성 | `StorageService.saveProfile()` | `ProfileInputScreen` |
| 조회 | `StorageService.getProfiles()` | `HomeScreen` |
| 삭제 | `StorageService.deleteProfile()` | `HomeScreen` |

**저장소 구조**

```dart
// SharedPreferences에 JSON 문자열로 저장
{
  "profiles": "[{\"id\":\"...\",\"name\":\"지수\",\"age\":25,...},...]"
}
```

---

### 3. AI 메시지 생성 (OCR 기반)

**전체 플로우**

```
홈 화면 (프로필 선택)
    ↓
이미지 선택 화면 (갤러리/카메라)
    ↓
분석 중 화면 (OCR + LLM 처리)
    ↓
추천 답변 화면 (3개 답변 제시)
```

**1) 이미지 선택 화면 (`ImageSelectionScreen`)**

```dart
// 갤러리 또는 카메라에서 이미지 선택
final XFile? pickedFile = await _imagePicker.pickImage(
  source: ImageSource.gallery, // or ImageSource.camera
  imageQuality: 85,
);
```

**2) 분석 중 화면 (`AnalyzingScreen`)**

```dart
// 백엔드로 이미지 전송 (multipart/form-data)
final response = await _apiClient.analyzeImage(
  imagePath: widget.imagePath,
  userId: widget.userId,
);
```

**백엔드 API 호출 (`POST /rizz/analyze-image`)**

```dart
// lib/services/api_client.dart:analyzeImage()
final request = http.MultipartRequest('POST', url);

// 이미지 파일 추가
request.files.add(
  await http.MultipartFile.fromPath('image', imagePath),
);

// 메타데이터 추가
request.fields['user_id'] = userId;
request.fields['platform'] = platform;      // 기본값: 'kakao'
request.fields['relationship'] = relationship; // 기본값: 'first_meet'
request.fields['style'] = style;            // 기본값: 'banmal'
request.fields['tone'] = tone;              // 기본값: 'friendly'
request.fields['num_suggestions'] = numSuggestions.toString(); // 기본값: 3
```

**3) 추천 답변 화면 (`ResponseScreen`)**

```dart
// AI 생성 답변 3개 표시
RizzResponse {
  suggestions: [
    "어제 이야기 재밌었어! 오늘 하루는 어땠어?",
    "나 어제 너랑 얘기하면서 시간 가는 줄 몰랐어.",
    "잘 자고 일어나서 기분 좋은 하루 보내길!"
  ]
}
```

**클립보드 복사 기능**

```dart
// 답변 탭 → 클립보드에 자동 복사
await Clipboard.setData(ClipboardData(text: suggestion));
```

---

## 🎨 UI/UX Design

### 컬러 시스템

```dart
// 메인 컬러
const Color(0xFFFFF8F3)  // 배경 베이스
const Color(0xFFE89BB5)  // 메인 핑크
const Color(0xFF8B3A62)  // 다크 핑크
const Color(0xFFFFD4D4)  // 보더/포인트

// 그라데이션
LinearGradient(
  colors: [
    Color(0xFFFFF8F3),  // 좌상단
    Color(0xFFFFF0E6),
    Color(0xFFFFE4E1).withOpacity(0.5), // 우하단
  ],
)
```

### 주요 UI 컴포넌트

**1. 프로필 카드 (HomeScreen)**

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Color(0xFFFFD4D4), width: 1.5),
  ),
  child: Row([
    CircleAvatar(name[0]),  // 이름 첫 글자
    Column([
      Text(name),
      Text('25세 • ENFP • 여성'),
      Text(memo),
    ]),
    IconButton(Icons.delete_outline),
  ]),
)
```

**2. 분석 중 애니메이션 (AnalyzingScreen)**

```dart
// 스캐닝 라인 애니메이션 (2초 반복)
AnimatedBuilder(
  animation: _scannerController,
  builder: (context, child) {
    return Positioned(
      top: 20 + (_scannerController.value * 200),
      child: Container(
        height: 3,
        gradient: LinearGradient([
          Colors.transparent,
          Color(0xFFE89BB5).withOpacity(0.8),
          Colors.transparent,
        ]),
      ),
    );
  },
)
```

**3. 답변 카드 (ResponseScreen)**

```dart
// Slide-in 애니메이션 (0.15초 간격으로 순차 등장)
Transform.translate(
  offset: Offset(0, (1 - adjustedValue) * 30),
  child: Opacity(
    opacity: adjustedValue,
    child: SuggestionCard(),
  ),
)
```

---

## 📊 Data Flow

### 1. 앱 초기화

```
앱 시작
  ↓
SharedPreferences 확인
  ↓
user_id 있음? → 세션 복원
  ↓
user_id 없음? → anonymousLogin() → user_id 저장
  ↓
프로필 목록 로드 (StorageService)
  ↓
홈 화면 렌더링
```

### 2. 메시지 생성 플로우

```
프로필 선택 (HomeScreen)
  ↓
이미지 선택 (ImageSelectionScreen)
  ↓
analyzeImage() API 호출 (AnalyzingScreen)
  ↓
백엔드 OCR 처리 (3-5초)
  ↓
RizzResponse 수신
  ↓
추천 답변 표시 (ResponseScreen)
  ↓
답변 탭 → 클립보드 복사
```

### 3. 데이터 저장 위치

| 데이터 | 저장소 | 지속성 |
|--------|--------|--------|
| user_id | SharedPreferences | 앱 삭제 전까지 |
| is_premium | SharedPreferences | 앱 삭제 전까지 |
| profiles | SharedPreferences (JSON) | 앱 삭제 전까지 |
| 추천 답변 | 메모리 (State) | 화면 종료 시 삭제 |

---

## 🔌 API Integration

### Backend Endpoints

| Method | Path | Description | Status |
|--------|------|-------------|--------|
| POST | `/auth/anonymous` | 익명 로그인 | ✅ 연동 완료 |
| GET | `/auth/me/subscription` | 구독 상태 조회 | ✅ 연동 완료 |
| POST | `/billing/subscribe` | 프리미엄 전환 (테스트용) | ⚠️ 미사용 |
| POST | `/rizz/generate` | 텍스트 기반 생성 | ⚠️ 미사용 |
| POST | `/rizz/analyze-image` | 이미지 기반 생성 | ✅ 연동 완료 |

### API Client Usage

```dart
// lib/services/api_client.dart

final ApiClient _apiClient = ApiClient();

// 1. 익명 로그인
final session = await _apiClient.anonymousLogin();
// → UserSession { userId: "...", isPremium: false }

// 2. 구독 상태 조회
final session = await _apiClient.fetchSubscription(userId);
// → UserSession { userId: "...", isPremium: true }

// 3. 이미지 분석 (OCR + LLM)
final response = await _apiClient.analyzeImage(
  imagePath: '/path/to/image.jpg',
  userId: userId,
  numSuggestions: 3,
);
// → RizzResponse { suggestions: [...] }
```

---

## ✅ Current Implementation Status

### 완료된 기능 (Phase 1 완료)

- ✅ **익명 인증 시스템**
  - 앱 최초 실행 시 자동 user_id 생성
  - SharedPreferences에 세션 저장
  - 재방문 시 세션 복원

- ✅ **프로필 관리 (로컬)**
  - 프로필 생성 (이름, 나이, MBTI, 성별, 메모)
  - 프로필 목록 조회
  - 프로필 삭제
  - SharedPreferences JSON 저장

- ✅ **이미지 기반 메시지 생성 (OCR)**
  - 갤러리/카메라 이미지 선택
  - 이미지 프리뷰
  - 백엔드 OCR API 연동
  - 분석 중 애니메이션
  - 추천 답변 3개 표시
  - 클립보드 복사 기능

- ✅ **UI/UX**
  - 핑크 컬러 시스템
  - 그라데이션 배경
  - 부드러운 애니메이션
  - Material Design 3
  - 반응형 레이아웃

### Phase 2: 백엔드 Profile API 연동 (✅ 완료)

**완료 일자:** 2025-12-28

**완료 내용:**

1. ✅ **Profile 모델 백엔드 스키마 일치**
   - MBTI 필드 제거 (memo에 포함)
   - userId, updatedAt 필드 추가
   - fromJson/toJson 백엔드 snake_case 형식 지원

2. ✅ **Profile API 클라이언트 구현**
   - `createProfile()` - POST /profiles (201 상태 코드 지원)
   - `getProfiles()` - GET /profiles?user_id=xxx
   - `deleteProfile()` - DELETE /profiles/{id}

3. ✅ **ProfileInputScreen & HomeScreen API 연동**
   - 로컬 StorageService 완전 제거
   - 백엔드가 단일 진실 공급원(Single Source of Truth)
   - 프로필 생성/조회/삭제 모두 백엔드 API 사용

4. ✅ **analyzeImage API 개선**
   - profile_id 전달로 간소화
   - platform, relationship, style, tone 파라미터 제거
   - 백엔드에서 프로필 정보 기반 프롬프트 생성

5. ✅ **UI 개선**
   - 메모 입력 50자 제한 (오버플로우 해결)
   - 카메라 버튼 제거 (갤러리만 사용)
   - 이미지 선택 화면 레이아웃 최적화
   - 버튼 간격 조정 (16px 통일)

**백엔드 연동 상태:**
- ✅ 익명 로그인: `POST /auth/anonymous`
- ✅ 프로필 생성: `POST /profiles`
- ✅ 프로필 조회: `GET /profiles?user_id=xxx`
- ✅ 프로필 삭제: `DELETE /profiles/{id}`
- ✅ 이미지 분석: `POST /rizz/analyze-image` (profile_id 포함)

**다음 단계: Phase 4 (확장 기능)**

---

### Phase 3: UX 개선 및 프롬프트 최적화 (✅ 완료)

**완료 일자:** 2025-12-29

**완료 내용:**

1. ✅ **이미지 선택 화면 오버플로우 해결**
   - 프리뷰 높이: 400px → 360px
   - 고정 요소 합계: 704px → 664px
   - 모든 디바이스에서 안정적 표시

2. ✅ **클릭 영역 확대**
   - 프리뷰 영역 전체 클릭 가능 (GestureDetector 추가)
   - 클릭 가능 영역: 56px → 416px (+660% 증가)
   - 직관적인 인터랙션 개선

3. ✅ **버튼 명확화**
   - "다시 분석" → "다시 시작"
   - 사용자 혼란 감소

4. ✅ **백엔드 프롬프트 개선**
   - Few-shot 예시 추가 (한국어 메신저 스타일)
   - 짧고 캐주얼한 답변 생성
   - 메신저 특유 표현 (ㅎㅎ, ~, !) 반영
   - 프로필 정보 자연스럽게 활용

**개선 효과:**
- ✅ 사용성 대폭 향상 (클릭 영역 660% 증가)
- ✅ 한국어 답변 품질 개선 (더 자연스러운 메신저 톤)
- ✅ 레이아웃 안정성 확보 (오버플로우 해결)
- ✅ 명확한 액션 레이블 (사용자 혼란 감소)

**다음 단계: Phase 4 (확장 기능)**

---

## 🚧 Known Issues & Limitations

### 1. 프로필 데이터 동기화 없음
- **문제:** 프로필이 로컬에만 저장됨
- **영향:** 앱 삭제 시 프로필 소실, 백엔드 프롬프트에 활용 불가
- **해결:** Phase 2에서 백엔드 Profile API 연동

### 2. 프리미엄 구독 미사용
- **문제:** `is_premium` 플래그는 있지만 실제 사용 안 됨
- **영향:** 무료/유료 구분 없음, 광고 제어 불가
- **해결:** 백엔드 사용량 제한 API 연동 필요

### 3. 에러 핸들링 부족
- **문제:** 네트워크 오류 시 사용자 피드백 부족
- **예시:** OCR 실패, API 타임아웃, 이미지 용량 초과
- **해결:** 에러별 친절한 메시지 추가

### 4. 이미지 최적화 없음
- **문제:** 큰 이미지를 그대로 업로드
- **영향:** 네트워크 사용량 증가, 처리 속도 저하
- **해결:** 이미지 리사이징 및 압축 추가

---

## 🎯 Next Steps (우선순위)

### 1. 백엔드 Profile API 연동 (High Priority)
- API 클라이언트에 Profile CRUD 메서드 추가
- `analyzeImage`에 `profile_id` 파라미터 추가
- 로컬 StorageService → API 호출로 전환

### 2. 사용량 제한 UI (Medium Priority)
- 무료 사용자: 5회/일 제한 표시
- 프리미엄 사용자: 무제한 뱃지 표시
- 사용 횟수 게이지 추가

### 3. 에러 핸들링 개선 (Medium Priority)
- 네트워크 오류 처리
- OCR 실패 시 재시도 버튼
- 친절한 에러 메시지

### 4. 이미지 최적화 (Low Priority)
- 이미지 압축 (image 패키지)
- 리사이징 (최대 1024px)
- 업로드 진행률 표시

### 5. 실제 결제 연동 (Future)
- In-App Purchase (iOS/Android)
- 구독 플랜: 월 ₩4,900
- 영수증 검증

---

## 📝 Development Notes

### 시뮬레이터 실행

```bash
# iOS 시뮬레이터
open -a Simulator
flutter run

# Android 에뮬레이터
flutter emulators --launch <emulator_id>
flutter run
```

### 디버그 로그 확인

```dart
// lib/services/api_client.dart
print('API Response: ${response.body}');

// lib/screens/analyzing_screen.dart
print('Analysis error: $e');
```

### 로컬 백엔드 테스트

```dart
// lib/services/api_client.dart
static const String _baseUrl = 'http://localhost:8000';
// iOS 시뮬레이터는 localhost 사용 가능
// Android 에뮬레이터는 10.0.2.2 사용
```

### SharedPreferences 초기화 (테스트용)

```dart
// main.dart에 임시 추가
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // ⚠️ 모든 로컬 데이터 삭제
  runApp(const SyranoApp());
}
```

---

## 📄 License

MIT

---

**문서 버전:** 1.0  
**최종 수정일:** 2025-12-28  
**작성자:** Development Team  
**주요 특징:** 백엔드 OCR 기반 AI 메시지 생성, 로컬 프로필 관리