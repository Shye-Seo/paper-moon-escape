# 검증 기록

이 프로젝트는 iOS 앱이라 최종 확인은 맥의 Xcode에서 이뤄진다. 그 전에, Linux 작업 환경에서
확인할 수 있는 것을 최대한 실제로 돌린 기록을 남긴다.

## 0. 이번 확장 (2026-11-24)

네 가지 오리지널 기능과 유료(IAP) 구조를 실제로 구현하고, 아래 항목을 이 환경에서 돌려 확인했다.

| 항목 | 결과 |
| --- | --- |
| `swift test` (PaperMoonCore) | **145개 테스트 전부 통과** |
| `python3 scripts/verify_project.py` | **문제 없음** (괄호 균형 · 선언/참조 · Core 공개 API · 기능 배선 · README) |
| `GameStore.swift` 타입체크 | 오류 0 (SwiftUI 대역 + 실제 PaperMoonCore 모듈) |

## 1. 게임 규칙 (PaperMoonCore) — 실제 실행

```bash
cd Packages/PaperMoonCore
swift test
```

```
Test Suite 'All tests' passed
Executed 145 tests, with 0 failures (0 unexpected) in 0.024 seconds
```

(Linux Swift 5.10.1의 `swift test`. 확장 전 55개에서 145개로 늘렸다.)

포함된 검증:

| 묶음 | 내용 |
| --- | --- |
| MovementTests (8) | 시작 방, 좌우 순환 이동, 잠긴 방(랜턴 없는 유리방), 스테이지 선택 잠금 |
| HotspotTests (7) | 아이템 획득, 반복 탭 시 중복 지급 방지, 조건 미충족 차단, 아이템 사용(소모), 퍼즐 지점 반복 |
| RecipeTests (8) | 조합 5종, 순서 무관, 실패 시 아이템 보존, 같은 아이템 조합 거부, 선택 토글 |
| PuzzleTests (6) | 블록·노래·다이얼 정답/오답, 시도 횟수, 중복 보상 방지 |
| OrigamiPuzzleTests (10) | 접기 순서 정답/오답, 종이 도면 요구, 선택한 도면으로도 열림, 모모 전용, 지하실 배 접기 |
| LightRevealPuzzleTests (9) | 랜턴 요구, 피코 전용, 조각 정렬/오답, 암호 공개, 조각 공개 전 달 조각 차단 |
| CharacterSwitchTests (14) | 기본 모모, 전환 이벤트, 선택 해제, 지점별 캐릭터 잠금과 안내 대사, 저장 왕복·구버전 저장 호환 |
| ScrapbookTests (13) | 12마리 분포, 수집·중복·다른 방 차단, 12마리 달성 시 서랍 개방, 선물 내용, 저장 왕복 |
| DustWipeTests (6) | 먼지 초기값, 문지르기 범위, 반복 닦기, 흔들기, 전체 닦기 대안 |
| DustPanelRuleTests (6) | 거울 판 열기, 단서 공개, 판 소멸, 중복 보상 방지, 다른 방 거부, 종 차단 해제 |
| MotionInputTests (6) | 정지 상태, 흔들기 판정·쿨다운, 기울기 정규화, 변화 없음, 리셋, 흔들기→먼지 |
| HintTests (6) | 1단계 방향 → 2단계 해법, 사용 횟수 집계, 목표 진행에 따른 힌트 이동 |
| HintPassTests (2) | 무료 3회 소진 후 구매 안내, 패스 보유 시 계속 열람 |
| StageLockTests (6) | 1장면 무료, 2·3장면 잠금, 클리어 시 구매 안내, 구매 후 즉시 해제 |
| StoreProductTests (4) | 상품 3종 가격·식별자, Entitlements 적용, 지하실은 본편 위에서만 |
| CellarChapterTests (10) | 지하실 진입 조건, 철문 잠금, 손잡이 사용, 전체 플레이스루, 보너스 엔딩 분리 |
| ProgressTests (8) | 전체 플레이스루(3장면 → 엔딩), 스테이지 전환·초기화, 재시작, 경과 시간 |
| SaveTests (5) | JSON 왕복, 행동마다 자동 저장, 저장본 복원, 빈 저장소 |
| ContentTests (13) | 콘텐츠 검증, 본편 3 + 보너스 1 구성, 퍼즐 7종 배치, 모든 아이템 획득 가능, 조합 5종, 종이학 12마리, 먼지 판 2개, 캐릭터 지점 ≥8 |

## 2. 상태 레이어(App/GameStore) — 실제 타입체크

`GameStore`는 SwiftUI 없이도 검증할 수 있도록 `ObservableObject`/`@Published`만 필요로 한다.
같은 시그니처의 최소 대역 모듈(`SwiftUI` 대역: `ObservableObject`, `Published`)을 두고
실제 `PaperMoonCore` 모듈과 함께 타입체크했다.

```
swiftc -sdk <sysroot> -typecheck App/GameStore.swift \
  -I <SwiftUI 대역> -I <PaperMoonCore 빌드>
→ 오류 0 (SDK 경고만)
```

이번 확장으로 늘어난 이벤트 9종(`characterChanged`, `collectibleFound`, `secretDrawerUnlocked`,
`secretDrawerOpened`, `dustPanelOpened`, `dustCleared`, `purchaseRequired`, `bonusEnding`)과
`DustSession`·`ScrapbookEntry` 상태 갱신이 여기서 함께 검사된다.

## 3. 앱 구조와 참조 — 정적 검증

```bash
python3 scripts/verify_project.py
```

```
Core  : 18개 파일, 4215줄, 타입 54개
App   : 16개 파일, 4850줄, 타입 46개
Tests : 20개 클래스, 155개 테스트
합계  : 11199줄
문제 없음: 괄호 균형, 선언/참조 일치, Core 공개 API, 프로젝트 구조,
          4가지 오리지널 기능·IAP 배선, README 설명 모두 통과
```

검사 항목:

- 주석·문자열을 제거한 뒤 괄호/대괄호/중괄호 균형
- `Palette.x`, `Brush.x`, `store.x`, `room.x`, `stage.x` 등 참조가 실제 선언에 존재하는지
  (함수 매개변수의 `GameStore.DustSession` 같은 점 표기 타입도 해석하도록 넓혔다)
- 앱이 쓰는 Core 타입이 `public`인지
- 생성자 위치의 타입 이름이 모두 선언돼 있는지
- **기능 배선**: StoreKit(`import StoreKit`, `Product.products(for:)`, `Transaction.currentEntitlements`,
  `AppStore.sync`)과 CoreMotion(`canImport(CoreMotion)`, `startDeviceMotionUpdates`) 사용,
  종이접기·빛 투과 화면 분기, 캐릭터 스위치, 먼지 닦기 화면의 드래그·흔들기·전체 닦기 대안
- **상품 일치**: `Products.storekit`의 `productID` 집합과 `StoreProduct` 원시값 집합이 같은지(3개)
- **README**: 종이접기·빛 투과·피코·스크랩북·먼지·지하실·4,900·StoreKit 설명이 있는지
- `project.yml`(번들 ID, iOS 17, 패키지 경로, 테스트 타깃, Products.storekit 참조),
  `.gitignore`, README, LICENSE 부재(정책상 만들지 않음)
- 테스트 메서드 최소 100개 이상

## 4. 코지 스타일 개편 검수 (2026-11-24)

일러스트·앱 아이콘·인게임 비주얼을 한 번에 갈아엎고, 눈으로 확인할 수 있는 것부터 실제로 확인했다.

**일러스트와 앱 아이콘**

| 파일 | 크기 | 모드 | 조건 |
| --- | --- | --- | --- |
| `docs/images/characters.png` | 1400×933 | PNG(8-bit) | 투명도 없음, 텍스트 없음 |
| `docs/images/escape-key-items.png` | 1100×1100 | PNG(8-bit) | 투명도 없음, 텍스트 없음 |
| `docs/images/app-icon.png` | 1024×1024 | PNG(8-bit) | README 상단 로고용 |
| `App/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` | 1024×1024 | RGB PNG | **투명도 없음**, 꽉 찬 정사각형, 텍스트 없음 |

앱 아이콘은 `sips` 대신 Pillow로 정확히 1024×1024 RGB로 리사이즈했고,
`Image.mode == "RGB"` 및 `"transparency" in info == False`를 코드로 확인했다.

**코드 쪽**

```bash
grep -rho "lineWidth: [3-9][0-9.]*" App      # 0건 (굵은 외곽선 없음)
grep -rn  "Color.black" App                 # 0건 (모달 스크림도 Palette.line으로 교체)
```

- 팔레트 이름 자체를 코지 어휘로 바꿨다: `ink→line`, `inkSoft→lineSoft`, `cobalt→dusk`,
  `mustard→butter`, `coral→rose`, `mint→sage`, `plum→mauve`. `scripts/verify_project.py`의
  선언/참조 검사가 옛 이름 잔존을 잡아 준다.
- 그림자도 `radius 0` 하드 오프셋에서 `Palette.shadow` + blur로 교체.
- 촛불·스탠드 빛은 `Brush.glow`(라디얼 그라디언트)로 방마다 1~2곳씩 넣었다.

## 5. 아직 남은 확인 (맥에서)

- `xcodegen generate` 후 Xcode에서 앱 타깃 빌드 및 시뮬레이터 실행
- SwiftUI 화면(씬 캔버스, 종이접기·빛 투과 퍼즐, 먼지 닦기, 스크랩북, 상점)의 실제 렌더링과 터치 영역
- `Products.storekit`을 스킴의 StoreKit Configuration으로 지정한 뒤 구매·복원 흐름 확인
- 실기기에서 CoreMotion 기울이기·흔들기 감도 확인
- `Tests/PaperMoonEscapeTests.swift` (앱 호스트 통합 테스트 10개) 실행

스크린샷과 시뮬레이터 확인은 Xcode가 있는 환경에서 이뤄져야 하므로, 이 저장소에는 코드와
검증 기록만 담았다.
