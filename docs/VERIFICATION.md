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
Executed 55 tests, with 0 failures (0 unexpected) in 0.010 seconds
```

포함된 검증:

| 묶음 | 내용 |
| --- | --- |
| MovementTests (8) | 시작 방, 좌우 순환 이동, 잠긴 방(랜턴 없는 유리방), 스테이지 선택 잠금 |
| HotspotTests (6) | 아이템 획득, 반복 탭 시 중복 지급 방지, 조건 미충족 차단, 아이템 사용(소모), 퍼즐 지점 반복 |
| RecipeTests (8) | 조합 4종, 순서 무관, 실패 시 아이템 보존, 같은 아이템 조합 거부, 선택 토글 |
| PuzzleTests (6) | 블록·노래·다이얼 정답/오답, 시도 횟수, 중복 보상 방지 |
| HintTests (6) | 1단계 방향 → 2단계 해법, 사용 횟수 집계, 목표 진행에 따른 힌트 이동 |
| ProgressTests (7) | 전체 플레이스루(3스테이지 → 엔딩), 스테이지 전환·초기화, 재시작, 경과 시간 |
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
App   : 11개 파일, 2278줄, 타입 31개
Tests : 9개 클래스, 61개 테스트
문제 없음: 괄호 균형, 선언/참조 일치, Core 공개 API, 프로젝트 구조 모두 통과
```

검사 항목:

- 주석·문자열을 제거한 뒤 괄호/대괄호/중괄호 균형
- `Palette.x`, `Brush.x`, `store.x`, `room.x`, `stage.x` 등 참조가 실제 선언에 존재하는지
- 앱이 쓰는 Core 타입이 `public`인지
- 생성자 위치의 타입 이름이 모두 선언돼 있는지
- `project.yml`(번들 ID, iOS 17, 패키지 경로, 테스트 타깃), `.gitignore`, README, LICENSE 부재(정책상 만들지 않음)
- 테스트 메서드 최소 15개 이상

## 4. 아직 남은 확인 (맥에서)

- `xcodegen generate` 후 Xcode에서 앱 타깃 빌드 및 시뮬레이터 실행
- SwiftUI 화면(씬 캔버스, 인벤토리 바, 힌트·퍼즐 오버레이)의 실제 렌더링과 터치 영역
- `Tests/PaperMoonEscapeTests.swift` (앱 호스트 통합 테스트 6개) 실행

스크린샷과 시뮬레이터 확인은 Xcode가 있는 환경에서 이뤄져야 하므로, 이 저장소에는 코드와
검증 기록만 담았다.
