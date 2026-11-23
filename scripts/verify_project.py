#!/usr/bin/env python3
"""종이달 다락방 탈출 — 정적 검증 스크립트.

이 리포지토리는 Xcode가 필요한 iOS 앱이라 Linux/CI에서는 `xcodebuild`를 쓸 수 없다.
그래서 두 겹으로 검증한다.

1) `Packages/PaperMoonCore`는 순수 Swift라서 `swift test`로 실제 실행 검증을 한다.
   (테스트 50여 개: 아이템 획득/사용, 조합 규칙, 3종 퍼즐, 2단계 힌트, 스테이지 클리어,
    전체 플레이스루, 저장/복원, 콘텐츠 무결성)
2) SwiftUI 앱 레이어는 컴파일러 없이도 확인할 수 있는 것들을 이 스크립트가 본다.
   - 주석/문자열을 제거한 뒤 괄호·대괄호·중괄호 균형
   - 타입/멤버 선언 수집 후 `Palette.x`, `Brush.x`, `store.x` 참조가 실제로 선언돼 있는지
   - Core 타입을 앱에서 쓸 때 public으로 열려 있는지
   - 프로젝트 구조(project.yml, 패키지 경로, 타깃 소스)와 테스트 개수

사용법:
    python3 scripts/verify_project.py            # 검증
    python3 scripts/verify_project.py --verbose  # 수집한 선언까지 출력
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_DIR = ROOT / "App"
CORE_DIR = ROOT / "Packages" / "PaperMoonCore" / "Sources" / "PaperMoonCore"
CORE_TEST_DIR = ROOT / "Packages" / "PaperMoonCore" / "Tests" / "PaperMoonCoreTests"
APP_TEST_DIR = ROOT / "Tests"

TYPE_DECL = re.compile(r"\b(struct|class|enum|protocol|extension|actor)\s+([A-Za-z_]\w*)")
MEMBER_DECL = re.compile(r"\b(?:let|var|func|case)\s+([A-Za-z_]\w*)")
PROPERTY_DECL = re.compile(r"\b(?:let|var)\s+([A-Za-z_]\w*)\s*:\s*([A-Z][A-Za-z0-9_.]*)\??")


# ---------------------------------------------------------------------------
# Swift 소스 읽기
# ---------------------------------------------------------------------------

def strip_literals(text: str) -> str:
    """주석과 문자열 리터럴을 공백으로 바꾼다(줄바꿈은 유지).

    문자열 보간 안의 코드도 함께 지우지만, 보간식은 그 자체로 균형이 맞기 때문에
    괄호 균형 검사에는 영향을 주지 않는다.
    """
    out: list[str] = []
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j == -1 else j
            out.append(" " * (j - i))
            i = j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            j = n if j == -1 else j + 2
            out.append("".join("\n" if c == "\n" else " " for c in text[i:j]))
            i = j
        elif text.startswith('"""', i):
            j = text.find('"""', i + 3)
            j = n if j == -1 else j + 3
            out.append("".join("\n" if c == "\n" else " " for c in text[i:j]))
            i = j
        elif ch == '"':
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == '"':
                    j += 1
                    break
                if text[j] == "\n":
                    break
                j += 1
            out.append(" " * (j - i))
            i = j
        else:
            out.append(ch)
            i += 1
    return "".join(out)


@dataclass
class SwiftFile:
    path: Path
    raw: str
    code: str

    @property
    def rel(self) -> str:
        return str(self.path.relative_to(ROOT))


def swift_files(directory: Path) -> list[SwiftFile]:
    files = []
    for path in sorted(directory.rglob("*.swift")):
        raw = path.read_text(encoding="utf-8")
        files.append(SwiftFile(path, raw, strip_literals(raw)))
    return files


# ---------------------------------------------------------------------------
# 선언 수집
# ---------------------------------------------------------------------------

@dataclass
class TypeInfo:
    name: str
    kind: str
    is_public: bool
    members: set[str] = field(default_factory=set)


def collect_types(files: list[SwiftFile]) -> dict[str, TypeInfo]:
    types: dict[str, TypeInfo] = {}
    for file in files:
        depth = 0
        stack: list[tuple[str, int]] = []  # (type name, body depth)
        for line in file.code.splitlines():
            stripped = line.strip()
            decl = TYPE_DECL.search(stripped)
            if decl:
                name = decl.group(2)
                is_public = "public " in stripped or stripped.startswith("public")
                info = types.setdefault(name, TypeInfo(name, decl.group(1), is_public))
                info.is_public = info.is_public or is_public
                stack.append((name, depth + 1))

            member = MEMBER_DECL.search(stripped)
            if member and stack and depth >= stack[-1][1]:
                types[stack[-1][0]].members.add(member.group(1))

            depth += line.count("{") - line.count("}")
            while stack and depth < stack[-1][1]:
                stack.pop()
    return types


def check_balance(files: list[SwiftFile]) -> list[str]:
    problems = []
    pairs = {"(": ")", "[": "]", "{": "}"}
    closers = {v: k for k, v in pairs.items()}
    for file in files:
        stack: list[tuple[str, int]] = []
        line_no = 1
        for ch in file.code:
            if ch == "\n":
                line_no += 1
            elif ch in pairs:
                stack.append((ch, line_no))
            elif ch in closers:
                if not stack:
                    problems.append(f"{file.rel}:{line_no} 짝 없는 '{ch}'")
                elif stack[-1][0] != closers[ch]:
                    opener, opened_at = stack.pop()
                    problems.append(
                        f"{file.rel}:{opened_at} '{opener}' 가 {line_no}에서 '{ch}'로 닫힘"
                    )
                else:
                    stack.pop()
        for opener, opened_at in stack:
            problems.append(f"{file.rel}:{opened_at} '{opener}' 가 닫히지 않음")
    return problems


# ---------------------------------------------------------------------------
# 참조 검사
# ---------------------------------------------------------------------------

ACCESS_PATTERNS = {
    "Palette": re.compile(r"\bPalette\.([A-Za-z_]\w*)"),
    "Brush": re.compile(r"\bBrush\.([A-Za-z_]\w*)"),
    "GameStore": re.compile(r"\bstore\.([A-Za-z_]\w*)"),
}

# SwiftUI/Combine이 공짜로 주는 멤버라 선언 검사에서 뺀다.
BUILTIN_MEMBERS = {
    "objectWillChange", "self", "world",
}


def check_member_references(
    app_files: list[SwiftFile], types: dict[str, TypeInfo]
) -> list[str]:
    problems = []
    for type_name, pattern in ACCESS_PATTERNS.items():
        info = types.get(type_name)
        if info is None:
            problems.append(f"타입 {type_name} 선언을 찾지 못했다")
            continue
        for file in app_files:
            for match in pattern.finditer(file.code):
                member = match.group(1)
                if member in BUILTIN_MEMBERS:
                    continue
                if member not in info.members:
                    problems.append(
                        f"{file.rel}: {type_name}.{member} 참조 — {type_name}에 그런 멤버가 없다"
                    )
    return sorted(set(problems))


def check_core_visibility(
    app_files: list[SwiftFile], core_types: dict[str, TypeInfo]
) -> list[str]:
    problems = []
    used: set[str] = set()
    names = set(core_types)
    for file in app_files:
        for token in re.findall(r"\b[A-Z][A-Za-z0-9_]*\b", file.code):
            if token in names:
                used.add(token)
    for name in sorted(used):
        info = core_types[name]
        if not info.is_public:
            problems.append(f"앱에서 쓰는 Core 타입 {name}이 public이 아니다")
    return problems


STANDARD_MEMBERS = {
    "id", "rawValue", "hashValue", "description", "self", "isEmpty", "count",
    "first", "last", "map", "filter", "contains", "appending", "allCases",
}


def check_property_access(
    app_files: list[SwiftFile], all_types: dict[str, TypeInfo]
) -> list[str]:
    """`room.title`처럼 프로퍼티 접근이 실제 선언과 맞는지 본다.

    파일 안의 `let name: Type`과 함수 파라미터 `name: Type`을 모아
    가벼운 타입 추론을 한다.
    """
    problems: list[str] = []
    for file in app_files:
        symbols: dict[str, str] = {}
        for match in PROPERTY_DECL.finditer(file.code):
            symbols[match.group(1)] = match.group(2)
        for match in re.finditer(r"(?:func\s+\w+|init)\s*\(([^)]*)\)", file.code):
            for param in re.finditer(
                r"([A-Za-z_]\w*)\s*:\s*([A-Z][A-Za-z0-9_]*)\??", match.group(1)
            ):
                symbols[param.group(1)] = param.group(2)

        for match in re.finditer(r"\b([a-z][A-Za-z0-9_]*)\.([A-Za-z_]\w*)", file.code):
            base, member = match.group(1), match.group(2)
            type_name = symbols.get(base)
            if type_name is None:
                continue
            info = all_types.get(type_name)
            if info is None and "." in type_name:
                info = all_types.get(type_name.split(".")[-1])
            if info is None or member in STANDARD_MEMBERS:
                continue
            if member not in info.members:
                problems.append(
                    f"{file.rel}: {base}.{member} — {type_name}에 '{member}' 선언이 없다"
                )
    return sorted(set(problems))


SWIFTUI_TYPES = {
    # Swift/SwiftUI/Foundation에서 오는 타입 (선언 검사 대상 아님)
    "Text", "Image", "Button", "VStack", "HStack", "ZStack", "Spacer", "ScrollView",
    "GeometryReader", "Canvas", "Path", "Color", "Font", "Circle", "Capsule",
    "RoundedRectangle", "Rectangle", "Ellipse", "Group", "ForEach", "Binding",
    "StrokeStyle", "Animation", "Edge", "Axis", "Alignment",
    "CGFloat", "CGPoint", "CGRect", "CGSize", "CGAffineTransform",
    "Date", "UUID", "URL", "Data", "Set", "Array", "Dictionary", "String", "Int",
    "Double", "Bool", "Void", "Character", "Optional", "Result", "Task",
    "DispatchQueue", "DispatchWorkItem", "Timer", "Error", "Never",
    "XCTestCase", "XCTAssert", "XCTAssertEqual", "XCTAssertTrue", "XCTAssertFalse",
    "XCTAssertNil", "XCTAssertNotNil", "XCTFail", "XCTAssertGreaterThan",
    "XCTAssertNotEqual", "XCTAssertGreaterThanOrEqual",
    "JSONEncoder", "JSONDecoder", "UserDefaults", "DateFormatter",
    "App", "Scene", "WindowGroup", "View", "ViewModifier", "ButtonStyle",
    "Configuration", "Content", "Body", "AnyView", "EmptyView", "MainActor",
    "Sendable", "Codable", "Identifiable", "Equatable", "Hashable", "CaseIterable",
    "Text", "Print", "Self",
}


def check_type_usage(files: list[SwiftFile], known: set[str]) -> list[str]:
    """`SomeView(`처럼 생성자 위치에 쓰인 타입 이름이 실제로 선언돼 있는지 본다."""
    problems: list[str] = []
    for file in files:
        for match in re.finditer(r"(?<![.\w])([A-Z][A-Za-z0-9_]*)\(", file.code):
            name = match.group(1)
            if name in known or name in SWIFTUI_TYPES:
                continue
            if name in {"static", "Self", "Self_"}:
                continue
            problems.append(f"{file.rel}: '{name}(' — 선언되지 않은 타입")
    return sorted(set(problems))


def check_project_structure() -> list[str]:
    problems = []
    project = ROOT / "project.yml"
    if not project.exists():
        return ["project.yml이 없다"]
    text = project.read_text(encoding="utf-8")
    required = [
        "com.quoguri.papermoonescape.app",
        'iOS: "17.0"',
        "Packages/PaperMoonCore",
        "PaperMoonEscapeTests",
    ]
    for needle in required:
        if needle not in text:
            problems.append(f"project.yml에 '{needle}'가 없다")

    package_manifest = ROOT / "Packages" / "PaperMoonCore" / "Package.swift"
    if not package_manifest.exists():
        problems.append("Package.swift가 없다")

    if (ROOT / "LICENSE").exists():
        problems.append("LICENSE는 만들지 않기로 했다(All Rights Reserved)")

    if not (ROOT / ".gitignore").exists():
        problems.append(".gitignore가 없다")

    for path in [
        ROOT / "App" / "PaperMoonEscapeApp.swift",
        ROOT / "README.md",
        ROOT / "Tests" / "PaperMoonEscapeTests.swift",
    ]:
        if not path.exists():
            problems.append(f"{path.relative_to(ROOT)} 가 없다")

    # 앱 타깃 소스가 App 디렉터리 전체를 포함하는지
    if "path: App" not in text:
        problems.append("project.yml의 앱 타깃이 App 디렉터리를 포함하지 않는다")
    return problems


def count_tests(files: list[SwiftFile]) -> tuple[int, int]:
    classes = 0
    methods = 0
    for file in files:
        classes += len(re.findall(r"class\s+\w+\s*:\s*XCTestCase", file.code))
        methods += len(re.findall(r"\n\s*func\s+test\w+\s*\(", file.code))
    return classes, methods


# ---------------------------------------------------------------------------
# 메인
# ---------------------------------------------------------------------------

def main() -> int:
    verbose = "--verbose" in sys.argv

    app_files = swift_files(APP_DIR)
    core_files = swift_files(CORE_DIR)
    core_test_files = swift_files(CORE_TEST_DIR)
    app_test_files = swift_files(APP_TEST_DIR)

    if not app_files:
        print("App/ 아래에 Swift 파일이 없다")
        return 1
    if not core_files:
        print("Core 소스가 없다")
        return 1

    core_types = collect_types(core_files)
    app_types = collect_types(app_files)

    problems: list[str] = []
    problems += check_balance(app_files + core_files + core_test_files + app_test_files)
    problems += check_member_references(app_files, {**core_types, **app_types})
    problems += check_core_visibility(app_files, core_types)
    problems += check_property_access(app_files, {**core_types, **app_types})
    problems += check_type_usage(app_files + core_files + core_test_files + app_test_files,
                                set(core_types) | set(app_types))
    problems += check_project_structure()

    core_classes, core_methods = count_tests(core_test_files)
    app_classes, app_methods = count_tests(app_test_files)
    if core_methods + app_methods < 15:
        problems.append(f"테스트 메서드가 {core_methods + app_methods}개뿐이다(최소 15개)")

    app_lines = sum(len(f.raw.splitlines()) for f in app_files)
    core_lines = sum(len(f.raw.splitlines()) for f in core_files)
    test_lines = sum(len(f.raw.splitlines()) for f in core_test_files + app_test_files)

    print("종이달 다락방 탈출 · 정적 검증")
    print(f"  Core  : {len(core_files)}개 파일, {core_lines}줄, 타입 {len(core_types)}개")
    print(f"  App   : {len(app_files)}개 파일, {app_lines}줄, 타입 {len(app_types)}개")
    print(f"  Tests : {core_classes + app_classes}개 클래스, {core_methods + app_methods}개 테스트")
    print(f"  합계  : {core_lines + app_lines + test_lines}줄")
    print()

    if verbose:
        for name in sorted(core_types):
            info = core_types[name]
            print(f"  [{'public' if info.is_public else 'internal'}] {info.kind} {name}"
                  f" · 멤버 {len(info.members)}개")

    if problems:
        print(f"문제 {len(problems)}건:")
        for problem in problems:
            print("  -", problem)
        return 1

    print("문제 없음: 괄호 균형, 선언/참조 일치, Core 공개 API, 프로젝트 구조 모두 통과")
    return 0


if __name__ == "__main__":
    sys.exit(main())
