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
- 사용량 UI 시스템 구축

**Phase 4 (구독 시스템):** ✅ **완료** (2026-01-01)
- 프리미엄 구독 화면 구현
- 백엔드 구독 API 연동
- 무료/프리미엄 UI 분기
- 구독 상태 백엔드 검증
- AppBar 가독성 개선

**Phase 5 (설정 & 구독 관리):** ✅ **완료** (2026-01-02)
- 설정 화면 구현
- 사용자 ID 표시 및 복사
- 구독 정보 표시
- 문의하기 (user_id 자동 포함)
- 구독 관리 화면 연동 (Apple/Google)
- 2가지 구독 관리 접근 경로

**Phase 6 (실제 결제 연동):** 🔴 **다음 작업**

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

### Phase 4 (2026-01-01)
- ✅ SubscriptionScreen 구현 (주간/월간 플랜 선택)
- ✅ 백엔드 구독 API 연동 (POST /billing/subscribe)
- ✅ SharedPreferences에 is_premium 저장
- ✅ 홈 화면 무료/프리미엄 UI 분기
- ✅ PRO 배지 (골드 그라데이션)
- ✅ 프리미엄 가입 버튼 (핑크 그라데이션)
- ✅ 설정 버튼 추가 (준비 중 안내)
- ✅ 구독 성공 시 홈 화면 새로고침
- ✅ 앱 시작 시 백엔드 구독 상태 검증 (fetchSubscription)
- ✅ 앱 복귀 시 재검증 (구독 만료 감지)
- ✅ SharedPreferences 조작 방지 (서버가 진실 공급원)
- ✅ AppBar 배경색 개선 (Color(0xFFC8879E))
- ✅ 상태바 가독성 향상

### Phase 5 (2026-01-02)
- ✅ SettingsScreen 구현
- ✅ 사용자 ID 표시 및 클립보드 복사
- ✅ 구독 정보 섹션 (프리미엄만)
- ✅ 문의하기 (user_id, 앱 버전, 플랫폼 자동 포함)
- ✅ 앱 버전 표시
- ✅ PRO 배지 → 구독 정보 다이얼로그
- ✅ 구독 관리 화면 연동 (2가지 경로)
- ✅ FAQ 제거 (악용 방지)
- ✅ UserSession 모델 확장 (planType, expiresAt)
- ✅ url_launcher 패키지 추가

---

## 🔴 High Priority (Phase 6)

### ~~1. 프리미엄 구독 정보 표시~~ ✅ **완료** (Phase 5)

### ~~2. 만료 임박 알림 (홈 화면 배너)~~ ⏸️ **보류**

**보류 이유:**
- 정상적인 자동 갱신 시 불필요한 알림
- 실제 필요 시점: 구독 취소 또는 결제 실패
- 백엔드에 `subscription_status` 필드 필요
- IAP 연동 후 구현 예정

**향후 구현 시:**
- 조건: `subscription_status == 'canceled'` 또는 `'payment_failed'`
- 위치: 홈 화면 상단 배너
- 메시지: "구독이 취소되었습니다. N일 후 만료" 또는 "결제 실패"

---

### 1. 실제 결제 프로세스 구현 (In-App Purchase)
**상태:** 🔴 **다음 작업**

**Phase 6-1: Flutter 앱 구현**

**필요한 패키지:**
```yaml
dependencies:
  in_app_purchase: ^3.1.11
```

**구현 내용:**
1. **상품 ID 정의**
```dart
   // App Store Connect / Play Console 등록
   const String weeklyPlanId = 'syrano_weekly_plan';
   const String monthlyPlanId = 'syrano_monthly_plan';
```

2. **구매 플로우 구현**
```dart
   // subscription_screen.dart
   Future<void> _startSubscription() async {
     // 1. 상품 정보 조회
     final response = await InAppPurchase.instance.queryProductDetails({
       _selectedPlan == PricingPlan.weekly ? weeklyPlanId : monthlyPlanId,
     });
     
     // 2. Apple/Google 결제 창 띄우기
     await InAppPurchase.instance.buyNonConsumable(
       purchaseParam: PurchaseParam(
         productDetails: response.productDetails.first,
         applicationUserName: widget.userId,
       ),
     );
   }
```

3. **구매 완료 이벤트 처리**
```dart
   InAppPurchase.instance.purchaseStream.listen((purchases) {
     for (final purchase in purchases) {
       if (purchase.status == PurchaseStatus.purchased) {
         // 영수증을 백엔드로 전송
         _verifyPurchase(purchase);
       }
     }
   });
```

**Phase 6-2: 백엔드 구현**

**필요한 API:**
1. **영수증 검증**
```python
   @router.post("/billing/verify-receipt")
   async def verify_receipt(
       user_id: str,
       receipt_data: str,
       platform: str  # "ios" or "android"
   ):
       # Apple/Google API로 영수증 검증
       # expires_at 추출 및 DB 업데이트
       pass
```

2. **Webhook 수신 (자동 갱신)**
```python
   @router.post("/billing/webhook/apple")
   async def apple_webhook(notification: dict):
       # Apple Server Notifications 수신
       # 자동 갱신 성공/실패 처리
       pass
```

**DB 스키마 (이미 완료):**
```sql
-- ✅ 이미 추가됨
ALTER TABLE subscriptions
ADD COLUMN transaction_id VARCHAR(255) NULL,
ADD COLUMN platform VARCHAR(10) NULL,
ADD COLUMN original_transaction_id VARCHAR(255) NULL;
```

**Phase 6-3: App Store / Play Console 설정**

1. **App Store Connect**
   - 앱 내 구입 → 자동 갱신 구독 생성
   - 주간 플랜: ₩1,900/주
   - 월간 플랜: ₩4,900/월

2. **Google Play Console**
   - 인앱 상품 → 정기 결제 생성
   - 동일한 가격 및 기간 설정

**예상 시간:** 12~16시간

**우선순위:**
- 🔴 Phase 6-1 (Flutter) - 가장 중요
- 🟡 Phase 6-2 (백엔드) - 동시 진행
- 🟢 Phase 6-3 (설정) - 마지막

**Phase 6-4: 구독 복원 구현**

**설정 화면에 추가:**
- "구독 복원" 버튼
- restorePurchases() 호출
- 영수증 기반 자동 복원

**예상 시간:** 1~2시간

---

## 🟡 Medium Priority

### ~~2. 설정 화면 구현~~ ✅ **완료** (Phase 5)

---

### 3. 에러 처리 개선
**상태:** ⏸️ **대기**

**개선 항목:**
- 네트워크 오류 재시도 로직
- 사용자 친화적 에러 메시지
- 로딩 상태 개선
- OCR 실패 시 재시도 버튼

**예상 시간:** 3시간

---

## 🟢 Low Priority

### 4. 디자인 개선
**상태:** ⏸️ **대기**

**개선 방향:**
- 온보딩 화면
- 스플래시 화면
- Micro-interactions
- 다크 모드 지원

**예상 시간:** 8시간

---

### 5. 히스토리 기능
**상태:** ⏸️ **대기**

**기능:**
- 과거 생성한 답장 저장
- 히스토리 화면 추가
- 즐겨찾기 기능

**예상 시간:** 6시간

---

## 📝 Notes

### 현재 상태 (2026-01-02)
- ✅ Phase 1, 2, 3, 4, 5 완료
- ✅ 백엔드 완전 연동
- ✅ 구독 시스템 (테스트용)
- ✅ 구독 상태 백엔드 검증
- ✅ 설정 화면
- ✅ 구독 관리 (Apple/Google 연동)
- ✅ 수동 구독 복원 프로세스 구축

### Phase 6 우선순위
1. 🔴 Flutter IAP 구현 (4~6시간)
2. 🔴 백엔드 영수증 검증 (3~4시간)
3. 🔴 App Store/Play Console 설정 (2~3시간)
4. 🔴 Webhook 구현 (2~3시간)
5. 🔴 구독 복원 자동화 (1~2시간)

**총 예상 시간:** 12~18시간

### 구독 복원 전략 (현재)
- **익명 로그인 한계:** 앱 재설치 시 user_id 변경
- **수동 복원 프로세스:**
  1. 사용자 → 설정 > 사용자 ID 복사
  2. support@syrano.app으로 문의 (구독 날짜 또는 영수증)
  3. 관리자 → DB에서 transaction_id 검색
  4. user_id 변경 또는 새 구독 생성
  5. 24시간 내 복원 완료
- **장기 해결책:** 소셜 로그인 추가

---

## 🎯 Next Steps

**현재 완료 (Phase 5):**
- ✅ 설정 화면
- ✅ 구독 정보 다이얼로그
- ✅ 구독 관리 연동

**다음 우선순위:**

### 🔴 Phase 6: 실제 결제 연동 (High Priority)

**예상 시간:** 12~16시간

#### 6-1: Flutter IAP 구현
- [ ] `in_app_purchase` 패키지 추가
- [ ] 상품 ID 정의 (syrano_weekly_plan, syrano_monthly_plan)
- [ ] `_startSubscription()` 수정 (Apple/Google 결제 창)
- [ ] `purchaseStream` 리스닝
- [ ] 영수증 백엔드 전송

#### 6-2: 백엔드 영수증 검증
- [x] DB 스키마 수정 (transaction_id, platform, original_transaction_id) ✅ 완료
- [ ] `POST /billing/verify-receipt` API 구현
- [ ] Apple/Google 영수증 검증 로직
- [ ] transaction_id 기반 구독 복원

#### 6-3: App Store / Play Console 설정
- [ ] App Store Connect 상품 등록
- [ ] Play Console 상품 등록
- [ ] 가격 설정 (₩1,900/주, ₩4,900/월)
- [ ] 테스트 계정 생성

#### 6-4: 자동 갱신 Webhook
- [ ] `POST /billing/webhook/apple` 구현
- [ ] `POST /billing/webhook/google` 구현
- [ ] 갱신/취소/환불 이벤트 처리

#### 6-5: 구독 복원
- [ ] `restorePurchases()` 구현
- [ ] 복원 UI (설정 화면)
- [ ] 자동 복원 플로우

---

### 🟡 Phase 7: UX 개선 (Medium Priority)

**예상 시간:** 4~6시간

- [ ] 구독 만료 알림 (조건부)
- [ ] 에러 처리 개선
- [ ] 로딩 상태 최적화
- [ ] 온보딩 화면

---

### 🟢 Phase 8: 추가 기능 (Low Priority)

**예상 시간:** 8~10시간

- [ ] 히스토리 기능
- [ ] 다크 모드
- [ ] 소셜 로그인 (구독 복원 개선)

---

*최종 업데이트: 2026-01-02*