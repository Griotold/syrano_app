# TODO - Syrano Flutter App

## 📊 Progress Summary

**Phase 1 (MVP):** ✅ **완료** (2025-12-27)  
- 익명 인증 시스템
- 로컬 프로필 관리
- 이미지 기반 OCR + AI 메시지 생성
- 기본 UI/UX

**Phase 2 (백엔드 연동):** ✅ **완료** (2025-12-28)
- Profile 모델 백엔드 스키마 일치
- Profile API 완전 연동
- analyzeImage API 개선 (profile_id 전달)
- UI 최적화 (메모 제한, 레이아웃 개선)

**Phase 3 (UX 개선):** ✅ **완료** (2025-12-29)
- 이미지 선택 화면 오버플로우 해결
- 클릭 영역 확대 및 버튼 명확화
- 백엔드 프롬프트 Few-shot 예시 추가

**Phase 4 (확장 기능):** 🔴 **다음 작업**

---

## ✅ Completed Tasks

### Phase 1 (2025-12-27)
- ✅ 익명 로그인 구현
- ✅ 로컬 프로필 CRUD
- ✅ 이미지 선택 (갤러리/카메라)
- ✅ OCR + AI 답변 생성
- ✅ 5개 화면 구현

### Phase 2 (2025-12-28)
- ✅ Profile 모델 MBTI 제거
- ✅ Profile API 클라이언트 (createProfile, getProfiles, deleteProfile)
- ✅ ProfileInputScreen API 연동
- ✅ HomeScreen API 연동
- ✅ StorageService 제거 (백엔드가 단일 진실 공급원)
- ✅ analyzeImage에 profile_id 추가
- ✅ 메모 입력 50자 제한
- ✅ 카메라 버튼 제거 (갤러리만 사용)
- ✅ 이미지 선택 화면 레이아웃 최적화
- ✅ 버튼 간격 조정 (16px 통일)

### Phase 3 (2025-12-29)
- ✅ 이미지 선택 화면 오버플로우 해결 (400px → 360px)
- ✅ 프리뷰 영역 전체 클릭 가능 (GestureDetector 추가)
- ✅ 클릭 영역 대폭 확대 (56px → 416px, +660%)
- ✅ "다시 분석" → "다시 시작" 버튼 명확화
- ✅ 백엔드 프롬프트 Few-shot 예시 추가
- ✅ 한국어 메신저 스타일 답변 개선 (짧고 캐주얼)
- ✅ 사용량 UI 시스템 구축 (UsageBadge 위젯)
- ✅ 3개 화면에 사용량 표시 (HomeScreen, ImageSelectionScreen, ResponseScreen)
- ✅ 백엔드 사용량 API 연동 (GET /billing/usage)
- ✅ 사용량 안내 다이얼로그 (상황별 차별화된 메시지)
- ✅ 프리미엄 전환 유도 (사용량 소진 시)

---

## 🔴 High Priority (Phase 4)

### 1. 구독 화면 구현
**상태:** 🔴 **다음 작업**

**기능:**
- 프리미엄 플랜 소개 (무제한 생성, 광고 제거)
- 주간/월간 플랜 선택
- 결제 화면 연동 (MVP: 버튼만)

**예상 시간:** 4시간

---

### 2. 에러 처리 개선
**상태:** ⏸️ **대기**

**개선 항목:**
- 네트워크 오류 재시도 로직
- 사용자 친화적 에러 메시지
- 로딩 상태 개선

**예상 시간:** 3시간

---

## 🟡 Medium Priority

### 3. 설정 화면 추가
**상태:** ⏸️ **대기**

**필요한 이유:**
- 앱 삭제 시 프리미엄 구독 정보 소실 문제 대응
- 수동 고객 지원 채널 필요

**구현 내용:**

```dart
// lib/screens/settings_screen.dart
Scaffold(
  appBar: AppBar(title: Text('설정')),
  body: ListView(
    children: [
      // 구독 관리
      ListTile(
        leading: Icon(Icons.star),
        title: Text('프리미엄 업그레이드'),
        onTap: () { /* 결제 화면 */ },
      ),
      
      // 문의하기
      ListTile(
        leading: Icon(Icons.email),
        title: Text('문의하기'),
        subtitle: Text('support@syrano.app'),
        onTap: () {
          launch('mailto:support@syrano.app?subject=문의사항');
        },
      ),
      
      // 구독 복구 (프리미엄만)
      if (isPremium)
        ListTile(
          leading: Icon(Icons.restore),
          title: Text('구독 복구 요청'),
          onTap: () {
            launch('mailto:support@syrano.app?subject=구독 복구 요청');
          },
        ),
      
      // FAQ
      ListTile(
        leading: Icon(Icons.help),
        title: Text('자주 묻는 질문'),
      ),
      
      // 앱 정보
      ListTile(
        leading: Icon(Icons.info),
        title: Text('앱 정보'),
        subtitle: Text('버전 1.0.0'),
      ),
    ],
  ),
)
```

**의존성:**
```yaml
dependencies:
  url_launcher: ^6.2.0  # 이메일 앱 열기
```

**예상 시간:** 3시간

---

### 4. 디자인 개선
**상태:** ⏸️ **대기**

**개선 방향:**
- 온보딩 화면
- 스플래시 화면
- Micro-interactions
- 다크 모드 지원

**예상 시간:** 8시간

---

## 🟢 Low Priority

### 5. 히스토리 기능
**상태:** ⏸️ **대기**

**기능:**
- 과거 생성한 답장 저장
- 히스토리 화면 추가
- 즐겨찾기 기능

**예상 시간:** 6시간

---

### 6. 실제 결제 연동
**상태:** ⏸️ **대기**

**기능:**
- In-App Purchase (iOS/Android)
- 영수증 검증
- 구독 복원

**예상 시간:** 12시간

---

## 📝 Notes

### 현재 상태 (2025-12-29)
- ✅ Phase 1, 2, 3 완료
- ✅ 백엔드 완전 연동
- ✅ UX 개선 완료
- ✅ 프롬프트 최적화 완료

### Phase 4 우선순위
1. 🟡 사용량 UI (2시간)
2. 🟡 에러 처리 (3시간)
3. 🟢 설정 화면 (3시간)
4. 🟢 디자인 개선 (8시간)

**총 예상 시간:** 16시간

---

## 🎯 Next Sprint

**목표:** 안정성 및 사용자 경험 개선

1. 사용량 제한 UI 표시
2. 에러 처리 개선
3. 설정 화면 추가
4. 실제 사용자 피드백 수집

**완료 기준:**
- ✅ 사용량 표시 (x/5회)
- ✅ 네트워크 에러 재시도
- ✅ 설정 화면 구현
- ✅ 사용자 테스트 완료

---

*최종 업데이트: 2025-12-29*