# 검증 기록

이 프로젝트는 iOS 앱이라 최종 확인은 맥의 Xcode에서 이뤄진다. 그 전에, Linux 작업 환경에서
확인할 수 있는 것을 최대한 실제로 돌린 기록을 남긴다.

## 0. 난이도 밸런스 · 미니게임 확장 (2026-11-24)

“3~4시간 만에 끝나는 난이도는 실패”, “스토리를 깬 뒤에도 한 번 더 즐길 것”이라는 요청으로
아이템 획득 확률과 퍼즐 난이도를 조정하고, 엔딩 뒤 놀이방(미니게임 2종)을 붙였다.

| 항목 | 결과 |
| --- | --- |
| `swift test` (PaperMoonCore) | **195개 테스트 전부 통과** (확장 전 145 + 50) |
| `python3 scripts/verify_project.py` | **문제 없음** (괄호 균형 · 선언/참조 · Core 공개 API · 탐색/퍼즐/놀이방 배선 · README) |
| `GameStore.swift` 타입체크 | 오류 0 (SwiftUI 대역 + 실제 PaperMoonCore 소스) |

### 0-1. 아이템 획득 확률 (탐색 지점 10곳)

한 번 누르면 바로 나오던 아이템 여섯 가지(종이 도면 · 짧은 초 · 맑은 유리병 · 반딧불이 ·
작은 톱니바퀴 · 녹슨 손잡이)를 **탐색 지점**으로 바꾸고, 수집품 네 개(종이학 3 · 우표 1)도
방을 깊이 더듬어야 나오게 했다.

| 자리 | 보상 | 시도별 확률 | 천장 |
| --- | --- | --- | --- |
| `attic.highShelf` (모모) | 종이 도면 | 0.45 / 0.75 / 1.0 | 3 |
| `attic.mouseHole` (피코) | 짧은 초 | 0.30 / 0.50 / 0.70 / 0.88 / 1.0 | 5 |
| `attic.toyShelfCrane` | 종이학 | 0.30 / 0.55 / 0.80 / 1.0 | 4 |
| `attic.curtainCrane` | 종이학 | 0.30 / 0.55 / 0.80 / 1.0 | 4 |
| `greenhouse.pondShelf` | 맑은 유리병 | 0.40 / 0.70 / 1.0 | 3 |
| `greenhouse.firefly` (피코) | 반딧불이 | 0.28 / 0.48 / 0.68 / 0.86 / 1.0 | 5 |
| `greenhouse.fireflyCrane` (랜턴 필요) | 종이학 | 0.30 / 0.55 / 0.80 / 1.0 | 4 |
| `tower.gearPile` (다이얼 먼저) | 작은 톱니바퀴 | 0.35 / 0.60 / 0.82 / 1.0 | 4 |
| `tower.woodBoxUnderside` | 옛날 우표 | 0.25 / 0.50 / 0.75 / 1.0 | 4 |
| `cellar.brickNook` (피코) | 녹슨 손잡이 | 0.40 / 0.70 / 1.0 | 3 |

- 마지막 확률은 **항상 1.0**(천장). `World.validate()`가 확률표의 마지막 값이 1.0인지,
  천장이 6번을 넘지 않는지, 확률이 오름차순인지, 관찰 문장·보상이 있는지 검사한다.
- 필수 아이템 기대 시도 횟수 합: 예전 6회(탭 6번) → 지금 약 **11.6회**. 전부 최악의 운이면 23회.
- `TestHelp.searchUntilFound`와 `Playthrough.unlucky`(주사위 0.99)로 **최악의 운에서도**
  풀 수 있음을 실제로 돌려 확인한다.

### 0-2. 퍼즐 난이도

| 퍼즐 | 바뀐 규칙 | 수치 |
| --- | --- | --- |
| 종이접기 (종이달 등불 · 양피지 배) | 접는 순간마다 도안과 대조. 틀리면 **접힘이 전부 풀려** 첫 접기부터 | 진행도 `foldProgress` 저장, 실수는 `puzzleAttempts`에 누적, 확인 단추 제거 |
| 빛 투과 (찢어진 종이창 · 라벨 암호) | 조각이 어긋난 만큼 글씨가 **흐릿**해지고 암호 앞부분만 보인다. 다 맞아야 확인 가능 | 흐림 반경 `(1-clarity) × 5.5` (0~5.5), 4조각 중 1개만 틀려도 clarity 0.75 → 흐림 1.375 |

### 0-3. 엔딩 뒤 다락방 놀이방 (미니게임 2종)

| 놀이 | 난이도 | 카드/도안 | 실수 허용 | 별 3개 조건 |
| --- | --- | --- | --- | --- |
| 다락방 기억의 서랍 (짝맞추기) | 포근한 오후 / 비 오는 저녁 / 달이 기우는 밤 | 4쌍·6쌍·8쌍 | – | 짝 수 +2번 이내 |
| 달빛 종이접기 연쇄 | 같은 3단계 | 3·5·7도안 | 3·2·1번 | 무실수 전부 완성 |

- 카드 그림은 본편 아이템 8종(종이학 · 우표 · 이어 붙인 열쇠 · 켜진 종이달 등불 · 기름등잔 ·
  접은 종이배 · 작은 톱니바퀴 · 반딧불이 랜턴), 접기 손동작은 본편 종이접기와 **같은 네 가지**
  (네 귀 모으기 · 가운데 누르기 · 아래로 접기 · 모양 펴기)를 쓴다.
- 해금: `GameEngine.playroomUnlocked` = 본편 엔딩(`finished`) 또는 종탑 클리어. 보너스 지하실만
  깬 상태로는 열리지 않는다(테스트로 확인).
- 기록은 `MiniGameRecords`로 `GameState`에 함께 저장된다(키 `memoryDrawer.easy` 꼴).
  최소 움직임·최고 연속 도안·최고 시간·플레이 횟수·최고 별을 유지한다.
- 진입: 타이틀과 본편 엔딩·보너스 엔딩 화면의 **다락방 놀이방** 단추 → `RootView`의 `.playroom` 단계.

## 1. 게임 규칙 (PaperMoonCore) — 실제 실행

```bash
cd Packages/PaperMoonCore
swift test
```

```
Test Suite 'All tests' passed
Executed 195 tests, with 0 failures (0 unexpected) in 0.136 seconds
```

(Linux Swift 5.10.1의 `swift test`. 초기 55개 → 145개 → 이번 확장으로 195개.)

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
| MotionInputTests (7) | 정지 상태, 흔들기 판정·쿨다운, 기울기 정규화, 변화 없음, 리셋, 흔들기→먼지 |
| HintTests (6) | 1단계 방향 → 2단계 해법, 사용 횟수 집계, 목표 진행에 따른 힌트 이동 |
| HintPassTests (2) | 무료 3회 소진 후 구매 안내, 패스 보유 시 계속 열람 |
| StageLockTests (6) | 1장면 무료, 2·3장면 잠금, 클리어 시 구매 안내, 구매 후 즉시 해제 |
| StoreProductTests (4) | 상품 3종 가격·식별자, Entitlements 적용, 지하실은 본편 위에서만 |
| CellarChapterTests (10) | 지하실 진입 조건, 철문 잠금, 손잡이 사용, 전체 플레이스루, 보너스 엔딩 분리 |
| ProgressTests (8) | 전체 플레이스루(3장면 → 엔딩), 스테이지 전환·초기화, 재시작, 경과 시간 |
| SaveTests (5) | JSON 왕복, 행동마다 자동 저장, 저장본 복원, 빈 저장소 |
| ContentTests (10) | 콘텐츠 검증, 본편 3 + 보너스 1 구성, 퍼즐 7종 배치, 모든 아이템 획득 가능, 조합 5종, 종이학 12마리, 먼지 판 2개, 캐릭터 지점 ≥8 |
| **SearchTests (17)** | 천장 보장, 확률 오름차순, 최악의 운에서 천장 발견, 첫 시도 발견, 관찰 문장, 중복 지급 방지, 캐릭터/도구/퍼즐/관찰 게이트, 탐색 전용 수집품, 저장·복원, 스테이지 초기화 |
| **FoldPenaltyTests (7)** | 순서대로 접기만 허용, 틀리면 전부 풀림, 실수 누적, 해결 후 무시, 손으로 펼치기, 진행도 저장, 지하실 배 |
| **LightReadoutTests (6)** | 완전 정렬 크리스프, 한 칸 오답 흐림, 완전 오답 점 처리, 빈 칸, 마스킹 길이·공백 보존, 비(非)빛 퍼즐 |
| **MemoryDrawerTests (8)** | 난이도별 카드 수, 카드 그림, 짝 판정, 어긋남 대기, 완벽/느슨한 기록의 별, 종료 후 무시, 기록 최고값 |
| **OrigamiChallengeTests (8)** | 난이도별 도안 수, 네 손동작의 서로 다른 순서, 도안 완성·다음 도안, 실수 시 풀림, 실수 소진 종료, 무실수 3별·1실수 2별, 최고 연쇄 기록 |
| **PlayroomTests (4)** | 엔딩 전 잠금, 엔딩 후 해금·기록, 기록 저장·복원, 지하실만 깬 상태로는 잠금 |

## 2. 상태 레이어(App/GameStore) — 실제 타입체크

`GameStore`는 SwiftUI 없이도 검증할 수 있도록 `ObservableObject`/`@Published`만 필요로 한다.
같은 시그니처의 최소 대역과 실제 `PaperMoonCore` 소스를 함께 타입체크했다.

```
swiftc -typecheck GameStore.swift <PaperMoonCore/Sources 전체>
→ 오류 0
```

이번 확장으로 늘어난 상태(`searches`, `searchProgress`, `foldSteps`, `searchFlash`,
`playroomUnlocked`, `miniGameRecords`)와 이벤트 5종(`searchMissed`, `searchFound`,
`foldAccepted`, `foldUnfolded`, `foldCleared`) 처리가 여기서 함께 검사된다.

## 3. 앱 구조와 참조 — 정적 검증

```bash
python3 scripts/verify_project.py
```

```
Core  : 21개 파일, 5414줄, 타입 69개
App   : 17개 파일, 5859줄, 타입 52개
Tests : 26개 클래스, 205개 테스트
합계  : 14123줄
문제 없음: 괄호 균형, 선언/참조 일치, Core 공개 API, 프로젝트 구조,
          4가지 오리지널 기능·IAP 배선, README 설명 모두 통과
```

검사 항목:

- 주석·문자열을 제거한 뒤 괄호/대괄호/중괄호 균형
- `Palette.x`, `Brush.x`, `store.x`, `room.x`, `stage.x` 등 참조가 실제 선언에 존재하는지
- 앱이 쓰는 Core 타입이 `public`인지
- 생성자 위치의 타입 이름이 모두 선언돼 있는지
- **기능 배선**: StoreKit·CoreMotion, 종이접기·빛 투과 화면 분기, 캐릭터 스위치, 먼지 닦기 대안
- **탐색·난이도·놀이방 배선**(이번 확장): `Search.swift`의 확률/천장 함수, `GameEngine.search`·
  `foldStep`·놀이방 기록 함수, 네 스테이지의 `searchSpots`, `PaperMoonWorld`의 합류,
  `Puzzle.resetText`와 `LightReadout`, `PuzzleOverlay`의 `onFold`·`lightReadout`·`blur(radius`,
  `GameView`의 탐색 링, `PlayroomView`의 두 보드와 기록 저장, `RootView`의 `.playroom` 진입
- `Products.storekit` ↔ `StoreProduct` 상품 일치(3개)
- **README**: 종이접기·빛 투과·피코·스크랩북·먼지·지하실·4,900·StoreKit + 더듬는 탐색·천장·
  놀이방·기억의 서랍·종이접기 연쇄·접힘 풀림·흐림 설명
- 테스트 메서드 최소 100개 이상 (현재 Core 195 + 앱 10)

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
  `mustard→butter`, `coral→rose`, `mint→sage`, `plum→mauve`.
- 그림자도 `radius 0` 하드 오프셋에서 `Palette.shadow` + blur로 교체.
- 촛불·스탠드 빛은 `Brush.glow`(라디얼 그라디언트)로 방마다 1~2곳씩 넣었다.
- 놀이방도 같은 팔레트·종이 카드(`paperCard`)·가는 코코아 선만 써서 본편과 톤을 맞췄다.

## 5. 아직 남은 확인 (맥에서)

- `xcodegen generate` 후 Xcode에서 앱 타깃 빌드 및 시뮬레이터 실행
- SwiftUI 화면(씬 캔버스, 탐색 링, 종이접기·빛 투과 퍼즐, 놀이방 두 보드)의 실제 렌더링과 터치 영역
- `Products.storekit`을 스킴의 StoreKit Configuration으로 지정한 뒤 구매·복원 흐름 확인
- 실기기에서 CoreMotion 기울이기·흔들기 감도 확인
- `Tests/PaperMoonEscapeTests.swift` (앱 호스트 통합 테스트 10개) 실행

스크린샷과 시뮬레이터 확인은 Xcode가 있는 환경에서 이뤄져야 하므로, 이 저장소에는 코드와
검증 기록만 담았다.
