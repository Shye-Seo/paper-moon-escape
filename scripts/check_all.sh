#!/bin/sh
# 두 겹 검증을 한 번에: 게임 규칙(swift test) + 구조 정적 검증.
set -e
cd "$(dirname "$0")/.."

echo "== 구조·참조 정적 검증 =="
python3 scripts/verify_project.py

echo
echo "== 게임 규칙 테스트 (PaperMoonCore) =="
cd Packages/PaperMoonCore
swift test
