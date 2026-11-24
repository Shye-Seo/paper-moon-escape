# 검증 기록

이 프로젝트는 iOS 앱이라 최종 확인은 맥의 Xcode에서 이뤄진다. 그 전에, Linux 작업 환경에서
확인할 수 있는 것을 최대한 실제로 돌린 기록을 남긴다.

## 1. 게임 규칙 (PaperMoonCore) — 실제 실행

```bash
cd Packages/PaperMoonCore
swift test
```

```
Test Suite 'All tests' passed
Executed 55 tests, with 0 failures (0 unexpected) in 0.212 seconds
```

(2026-11-24 코지 스타일 개편 이후 재실행. Linux Swift 5.10.1의 `swift test`로 55개 전부 통과.)

포함된 검증:

| 묶음 | 내용 |
| --- | --- |
| MovementTests (8) | 시작 방, 좌우 순환 이동, 잠긴 방(랜턴 없는 유리방), 스테이지 선택 잠금 |
| HotspotTests (7) | 아이템 획득, 반복 탭 시 중복 지급 방지, 조건 미충족 차단, 아이템 사용(소모), 퍼즐 지점 반복 |
| RecipeTests (8) | 조합 4종, 순서 무관, 실패 시 아이템 보존, 같은 아이템 조합 거부, 선택 토글 |
| PuzzleTests (6) | 블록·노래·다이얼 정답/오답, 시도 횟수, 중복 보상 방지 |
| HintTests (6) | 1단계 방향 → 2단계 해법, 사용 횟수 집계, 목표 진행에 따른 힌트 이동 |
| ProgressTests (8) | 전체 플레이스루(3스테이지 → 엔딩), 스테이지 전환·초기화, 재시작, 경과 시간 |
| SaveTests (5) | JSON 왕복, 행동마다 자동 저장, 저장본 복원, 빈 저장소 |
| ContentTests (7) | 콘텐츠 검증(참조·좌표·중복), 3×3 방 구성, 모든 아이템 획득 가능, 퍼즐 정답이 단순 순서가 아님 |

## 2. 상태 레이어(App/GameStore) — 실제 타입체크

`GameStore`는 SwiftUI 없이도 검증할 수 있도록 `ObservableObject`/`@Published`만 필요로 한다.
같은 시그니처의 최소 대역 모듈을 두고 실제 `PaperMoonCore` 모듈과 함께 타입체크했다.

```
swiftc -typecheck App/GameStore.swift -I <SwiftUI 대역> -I <PaperMoonCore 빌드>
→ 오류 0
```

엔진 이벤트 switch의 모든 케이스, `@Published` 상태 갱신, 저장소 호출, 타이머 클로저가 여기서 검사된다.

## 3. 앱 구조와 참조 — 정적 검증

```bash
python3 scripts/verify_project.py
```

```
Core  : 10개 파일, 2290줄, 타입 38개
App   : 11개 파일, 2618줄, 타입 30개
Tests : 9개 클래스, 61개 테스트
합계  : 5751줄
문제 없음: 괄호 균형, 선언/참조 일치, Core 공개 API, 프로젝트 구조 모두 통과
```

검사 항목:

- 주석·문자열을 제거한 뒤 괄호/대괄호/중괄호 균형
- `Palette.x`, `Brush.x`, `store.x`, `room.x`, `stage.x` 등 참조가 실제 선언에 존재하는지
- 앱이 쓰는 Core 타입이 `public`인지
- 생성자 위치의 타입 이름이 모두 선언돼 있는지
- `project.yml`(번들 ID, iOS 17, 패키지 경로, 테스트 타깃), `.gitignore`, README, LICENSE 부재(정책상 만들지 않음)
- 테스트 메서드 최소 15개 이상

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
어떤 그림을 실제로 설치했는지는 생성 결과를 `read_file`로 열어 눈으로 검수했다
(첨부 레퍼런스와 같은 가는 갈색 선화·점 눈·홍조·뮤트 파스텔 톤인지, 굵은 검정 외곽선이 없는지).

**코드 쪽**

```bash
grep -rho "lineWidth: [3-9][0-9.]*" App      # 0건 (굵은 외곽선 없음)
grep -rn  "Color.black" App                 # 0건 (모달 스크림도 Palette.line으로 교체)
grep -rho "Palette\.[a-zA-Z]*" App | sort -u # ink/cobalt/mustard/coral/mint/plum 잔존 0건
```

- 팔레트 이름 자체를 코지 어휘로 바꿨다: `ink→line`, `inkSoft→lineSoft`, `cobalt→dusk`,
  `mustard→butter`, `coral→rose`, `mint→sage`, `plum→mauve`. `scripts/verify_project.py`의
  선언/참조 검사가 옛 이름 잔존을 잡아 준다.
- 그림자도 `radius 0` 하드 오프셋에서 `Palette.shadow` + blur로 교체.
- 촛불·스탠드 빛은 `Brush.glow`(라디얼 그라디언트)로 방마다 1~2곳씩 넣었다.
- 캐릭터는 이모지 대신 SwiftUI 도형으로 그린다(작은 점 눈, 홍조, 얇은 코코아 윤곽).
  대사 화자 아바타도 이모지(`👦` 등)를 버리고 같은 화풍의 작은 얼굴로 바꿨다.
- `Gradient`/`RadialGradient`/`LinearGradient`는 SwiftUI 기본 타입이라 정적 검증의 타입 화이트리스트에 추가했다.

## 5. 아직 남은 확인 (맥에서)

- `xcodegen generate` 후 Xcode에서 앱 타깃 빌드 및 시뮬레이터 실행
- SwiftUI 화면(씬 캔버스, 인벤토리 바, 힌트·퍼즐 오버레이)의 실제 렌더링과 터치 영역
- `Tests/PaperMoonEscapeTests.swift` (앱 호스트 통합 테스트 6개) 실행

스크린샷과 시뮬레이터 확인은 Xcode가 있는 환경에서 이뤄져야 하므로, 이 저장소에는 코드와
검증 기록만 담았다.
