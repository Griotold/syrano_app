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
│   │   ├── profile.dart               # 프로필 모델
│   │   ├── user_session.dart          # 사용자 세션 (user_id, is_premium)
│   │   └── rizz_response.dart         # AI 응답 모델
│   ├── screens/                       # 화면 컴포넌트
│   │   ├── home_screen.dart           # 홈 화면 (프로필 목록)
│   │   ├── profile_input_screen.dart  # 프로필 입력 화면
│   │   ├── image_selection_screen.dart # 이미지 선택 화면
│   │   ├── analyzing_screen.dart      # 분석 중 화면
│   │   ├── response_screen.dart       # 추천 답변 화면
│   │   └── subscription_screen.dart   # 프리미엄 구독 화면
│   ├── widgets/                       # 재사용 위젯
│   │   ├── usage_badge.dart           # 사용량 배지
│   │   └── usage_dialog.dart          # 사용량 안내 다이얼로그
│   └── services/                      # 비즈니스 로직
│       ├── api_client.dart            # REST API 통신
│       └── storage_service.dart       # (제거됨 - 백엔드 완전 연동)
├── docs/
│   └── PRD.md                         # 제품 요구사항 문서
├── pubspec.yaml                       # 의존성 관리
├── README.md                          # 프로젝트 문서
└── TODO.md                            # 작업 목록
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
- 백엔드 API로 구독 상태 검증 (`GET /auth/me/subscription`)
- SharedPreferences 업데이트 (서버가 단일 진실 공급원)
- 네트워크 오류 시 로컬 캐시 사용 (fallback)

---

### 2. 프로필 관리 (백엔드 연동)

**프로필 데이터 구조**
```dart
// lib/models/profile.dart
class Profile {
  final String id;          // 백엔드 생성 고유 ID
  final String userId;      // 사용자 ID
  final String name;        // 상대방 이름 (필수)
  final int age;            // 나이 (필수)
  final String gender;      // 성별 (남성/여성/기타)
  final String? memo;       // 메모 (선택, 50자 제한)
  final DateTime createdAt; // 생성 시각
  final DateTime updatedAt; // 수정 시각
}
```

**CRUD 기능**

| 기능 | API | 화면 |
|------|-----|------|
| 생성 | `POST /profiles` | `ProfileInputScreen` |
| 조회 | `GET /profiles?user_id=xxx` | `HomeScreen` |
| 삭제 | `DELETE /profiles/{id}` | `HomeScreen` |

---

### 3. AI 메시지 생성 (OCR 기반)

**전체 플로우**
```
홈 화면 (프로필 선택)
    ↓
이미지 선택 화면 (갤러리)
    ↓
분석 중 화면 (OCR + LLM 처리)
    ↓
추천 답변 화면 (3개 답변 제시)
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
request.fields['profile_id'] = profileId;  // 프로필 정보 기반 개인화
request.fields['num_suggestions'] = numSuggestions.toString();
```

---

### 4. 프리미엄 구독 시스템

**구독 플로우**
```
무료 유저: "프리미엄 가입" 버튼 클릭
    ↓
구독 화면 (플랜 선택: 주간 ₩1,900 / 월간 ₩4,900)
    ↓
"프리미엄 시작하기" 버튼 클릭
    ↓
백엔드 API 호출 (POST /billing/subscribe)
    ↓
SharedPreferences 업데이트 (is_premium = true)
    ↓
홈 화면으로 복귀 → PRO 배지 표시
```

**구독 상태 검증**

- ✅ 앱 시작 시: 백엔드 API로 실제 구독 상태 확인
- ✅ 앱 복귀 시: 재검증하여 만료 감지
- ✅ SharedPreferences 조작 방지 (서버가 진실 공급원)

**무료 vs 프리미엄**

| 기능 | 무료 | 프리미엄 |
|------|------|----------|
| 메시지 생성 | 5회/일 | 무제한 |
| 광고 | 있음 (예정) | 없음 |
| UI 배지 | ♥ 3/5 | 👑 PRO |

---

### 5. 사용량 추적 시스템

**사용량 API**
```dart
// GET /billing/usage?user_id=xxx
{
  "is_premium": false,
  "remaining_count": 3,
  "daily_limit": 5,
  "used_count": 2
}
```

**UI 표시**

- **무료 유저:** 사용량 배지 (♥ 3/5)
- **프리미엄 유저:** PRO 배지 (👑 PRO)
- **사용량 0~1회:** "프리미엄 보기" 버튼 표시

---

## 🎨 UI/UX Design

### 컬러 시스템
```dart
// 메인 컬러
const Color(0xFFFFF8F3)  // 배경 베이스
const Color(0xFFE89BB5)  // 메인 핑크
const Color(0xFF8B3A62)  // 다크 핑크
const Color(0xFFC8879E)  // 중간 톤 핑크 (AppBar)
const Color(0xFFFFD4D4)  // 보더/포인트
const Color(0xFFFFD700)  // 골드 (PRO 배지)

// 그라데이션
LinearGradient(
  colors: [
    Color(0xFFFFF8F3),
    Color(0xFFFFF0E6),
    Color(0xFFFFE4E1).withOpacity(0.5),
  ],
)
```

### AppBar 디자인

- **배경:** `Color(0xFFC8879E)` (중간 톤 핑크)
- **타이틀/아이콘:** 흰색
- **상태바 가독성:** 시간, 네트워크, 배터리 잘 보임

---

## 📊 Data Flow

### 1. 앱 초기화
```
앱 시작
  ↓
SharedPreferences 확인
  ↓
user_id 있음?
  ├─ 있음: fetchSubscription() 백엔드 검증
  │   ↓
  │   is_premium 업데이트 (서버 값 우선)
  │   ↓
  │   네트워크 오류 시 캐시 사용
  │
  └─ 없음: anonymousLogin()
      ↓
      user_id, is_premium 저장
  ↓
프로필 목록 로드 (getProfiles)
  ↓
사용량 로드 (getUsage)
  ↓
홈 화면 렌더링
```

### 2. 구독 상태 동기화
```
앱 복귀 (didChangeAppLifecycleState.resumed)
  ↓
_verifySubscription() 호출
  ↓
fetchSubscription() 백엔드 검증
  ↓
상태 변경 감지?
  ├─ is_premium: true → false
  │   ↓
  │   "프리미엄 구독이 만료되었습니다" SnackBar
  │   ↓
  │   UI 업데이트 (PRO 배지 → 프리미엄 가입 버튼)
  │
  └─ 변경 없음: 유지
```

---

## 🔌 API Integration

### Backend Endpoints

| Method | Path | Description | Status |
|--------|------|-------------|--------|
| POST | `/auth/anonymous` | 익명 로그인 | ✅ 연동 완료 |
| GET | `/auth/me/subscription` | 구독 상태 조회 | ✅ 연동 완료 |
| POST | `/billing/subscribe` | 프리미엄 구독 (테스트용) | ✅ 연동 완료 |
| GET | `/billing/usage` | 사용량 조회 | ✅ 연동 완료 |
| POST | `/rizz/analyze-image` | 이미지 기반 생성 | ✅ 연동 완료 |
| POST | `/profiles` | 프로필 생성 | ✅ 연동 완료 |
| GET | `/profiles` | 프로필 목록 조회 | ✅ 연동 완료 |
| DELETE | `/profiles/{id}` | 프로필 삭제 | ✅ 연동 완료 |

---

## ✅ Current Implementation Status

### 완료된 기능 (Phase 1-4)

- ✅ **익명 인증 시스템**
  - 앱 최초 실행 시 자동 user_id 생성
  - 재방문 시 백엔드 검증 (구독 만료 감지)
  - 앱 복귀 시 재검증 (SharedPreferences 조작 방지)

- ✅ **프로필 관리 (백엔드 연동)**
  - 프로필 생성/조회/삭제 (백엔드 API)
  - 프로필 정보 기반 AI 답변 개인화

- ✅ **이미지 기반 메시지 생성 (OCR)**
  - 갤러리 이미지 선택
  - 백엔드 OCR + LLM 처리
  - 추천 답변 3개 표시
  - 클립보드 복사 기능

- ✅ **프리미엄 구독 시스템 (테스트용)**
  - 구독 화면 (주간/월간 플랜)
  - 백엔드 구독 API 연동
  - 무료/프리미엄 UI 분기
  - PRO 배지 (골드)

- ✅ **사용량 추적 시스템**
  - 사용량 배지 (♥ 3/5)
  - 사용량 안내 다이얼로그
  - 프리미엄 전환 유도

- ✅ **UI/UX**
  - 핑크 컬러 시스템
  - 그라데이션 배경
  - 부드러운 애니메이션
  - AppBar 가독성 개선

---

## 🚧 Known Limitations

### 1. 테스트용 구독 시스템
- **현재:** 백엔드 API만 호출 (실제 결제 없음)
- **향후:** Apple/Google In-App Purchase 연동 필요

### 2. 구독 만료 알림 없음
- **현재:** 앱 복귀 시에만 만료 감지
- **향후:** PRO 배지 탭 시 만료일 표시, 만료 3일 전 알림

### 3. 자동 결제 미구현
- **현재:** 수동으로 재구독 필요
- **향후:** Apple/Google 자동 갱신 구독

---

## 🎯 Next Steps

**다음 우선순위:**

1. 🔴 **프리미엄 구독 정보 표시** (High Priority)
   - PRO 배지 탭 → 구독 정보 다이얼로그
   - 만료일 표시 (expires_at)
   - 만료 3일 전 홈 화면 배너

2. 🟡 **설정 화면 구현** (Medium Priority)
   - 구독 관리
   - 문의하기
   - FAQ, 앱 정보

3. 🟡 **실제 결제 연동** (Medium Priority)
   - In-App Purchase (iOS/Android)
   - 영수증 검증
   - 자동 갱신 구독

4. 🟢 **에러 처리 개선** (Low Priority)
   - 네트워크 오류 재시도
   - 사용자 친화적 에러 메시지

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
// 구독 검증 로그
flutter: ✅ Subscription verified from backend: isPremium=true
flutter: 🔄 Subscription status changed: isPremium=false
flutter: ⚠️ Backend verification failed, using cached data
```

---

## 📄 License

MIT

---

**문서 버전:** 2.0  
**최종 수정일:** 2026-01-01  
**작성자:** Development Team  
**주요 특징:** 백엔드 완전 연동, 프리미엄 구독 시스템, 구독 상태 검증