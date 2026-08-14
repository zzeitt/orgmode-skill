#!/bin/bash
# Unit tests for orgmode-skill scripts
# Tests check-org-cjk-emphasis.sh and fix-org-cjk-emphasis.sh against
# known-good and known-bad fixture files.
#
# Usage:
#   ./tests/test-check-fix.sh          # run all tests
#   ./tests/test-check-fix.sh -v       # verbose: show per-test output
#   ./tests/test-check-fix.sh -x       # stop on first failure

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CHECK_SCRIPT="$PROJECT_DIR/scripts/check-org-cjk-emphasis.sh"
FIX_SCRIPT="$PROJECT_DIR/scripts/fix-org-cjk-emphasis.sh"
FIXTURES="$PROJECT_DIR/tests/fixtures"

PASS=0
FAIL=0
VERBOSE=false
STOP_ON_FAIL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v) VERBOSE=true; shift ;;
    -x) STOP_ON_FAIL=true; shift ;;
    *)  break ;;
  esac
done

# Colors (if stdout is a terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

# ---- Test helpers ----

runtest() {
  local name="$1"; shift
  if $VERBOSE; then
    echo -n "[TEST] $name ... "
  fi

  local output rc
  output=$("$@" 2>&1) && rc=$? || rc=$?

  if [ "$rc" -eq 0 ]; then
    PASS=$((PASS + 1))
    if $VERBOSE; then
      echo -e "${GREEN}PASS${NC}"
    fi
  else
    FAIL=$((FAIL + 1))
    if $VERBOSE; then
      echo -e "${RED}FAIL${NC} (exit=$rc)"
    fi
    echo -e "${RED}FAIL${NC}: $name"
    echo "  Command: $*"
    echo "  Output:"
    echo "$output" | sed 's/^/    /'
    if $STOP_ON_FAIL; then
      exit 1
    fi
  fi
  return "$rc"
}

# assert_exit CODE MSG CMD...
assert_exit() {
  local expect="$1" name="$2"; shift 2
  local output rc
  output=$("$@" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -eq "$expect" ]; then
    PASS=$((PASS + 1))
    if $VERBOSE; then
      echo -e "[TEST] $name ... ${GREEN}PASS${NC}"
    fi
  else
    FAIL=$((FAIL + 1))
    if $VERBOSE; then
      echo -e "[TEST] $name ... ${RED}FAIL${NC} (expected exit=$expect, got exit=$rc)"
    fi
    echo -e "${RED}FAIL${NC}: $name"
    echo "  Expected exit: $expect, got: $rc"
    echo "  Output:"
    echo "$output" | sed 's/^/    /'
    if $STOP_ON_FAIL; then
      exit 1
    fi
  fi
}

# assert_contains SEARCH MSG CMD...
assert_contains() {
  local search="$1" name="$2"; shift 2
  local output rc
  output=$("$@" 2>&1) && rc=$? || rc=$?
  if echo "$output" | grep -qF "$search"; then
    PASS=$((PASS + 1))
    if $VERBOSE; then
      echo -e "[TEST] $name ... ${GREEN}PASS${NC}"
    fi
  else
    FAIL=$((FAIL + 1))
    if $VERBOSE; then
      echo -e "[TEST] $name ... ${RED}FAIL${NC} (output missing \"$search\")"
    fi
    echo -e "${RED}FAIL${NC}: $name"
    echo "  Expected to contain: $search"
    echo "  Output:"
    echo "$output" | sed 's/^/    /'
    if $STOP_ON_FAIL; then
      exit 1
    fi
  fi
}

# ---- Prerequisite checks ----

echo "=== orgmode-skill Unit Tests ==="
echo ""

if [ ! -x "$CHECK_SCRIPT" ]; then
  echo -e "${RED}FATAL: check script not executable: $CHECK_SCRIPT${NC}"
  exit 1
fi
if [ ! -x "$FIX_SCRIPT" ]; then
  echo -e "${RED}FATAL: fix script not executable: $FIX_SCRIPT${NC}"
  exit 1
fi

# ---- check-org-cjk-emphasis.sh tests ----

echo "--- check-org-cjk-emphasis.sh ---"

# T1: Known-wrong file should FAIL
assert_exit 1 "check: wrong file fails" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-wrong.org"

# T2: Clean file should PASS
assert_exit 0 "check: clean file passes" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-ok.org"

# T3: Mixed file should FAIL (has errors outside blocks)
assert_exit 1 "check: mixed file fails" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-mixed.org"

# T4: Mixed file check should NOT flag =中文= inside src block
assert_contains "结果：=lto1=" "check: mixed detects line outside block" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-mixed.org"
assert_contains "对" "check: mixed detects math error outside block" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-mixed.org"

# T5: Wrong file should mention all delimiter types
assert_contains "lto1" "check: wrong file detects = touching CJK" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-wrong.org"
assert_contains "expr" "check: wrong file detects ~ touching CJK" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-wrong.org"
assert_contains "方案" "check: wrong file detects / touching CJK" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-wrong.org"
assert_contains "重点" "check: wrong file detects * touching CJK" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-wrong.org"
assert_contains "强调" "check: wrong file detects _ touching CJK" \
  bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-wrong.org"

# T6: Wrong file should mention fix hint
check_output=$(bash "$CHECK_SCRIPT" "$FIXTURES/cjk-emphasis-wrong.org" 2>&1) || true
if echo "$check_output" | grep -qi "Fix"; then
  PASS=$((PASS + 1))
  $VERBOSE && echo -e "[TEST] check: error output includes fix hint ... ${GREEN}PASS${NC}"
else
  FAIL=$((FAIL + 1))
  echo -e "${RED}FAIL${NC}: check: error output includes fix hint"
fi

# ---- fix-org-cjk-emphasis.sh tests ----

echo ""
echo "--- fix-org-cjk-emphasis.sh ---"

FIX_TMP=$(mktemp -d)
trap "rm -rf $FIX_TMP" EXIT

# T7: Dry-run on clean file should say OK
assert_exit 0 "fix: dry-run clean file" \
  bash "$FIX_SCRIPT" "$FIXTURES/cjk-emphasis-ok.org"

# T8: Dry-run on wrong file should show changes
assert_contains "would be changed" "fix: dry-run shows pending changes" \
  bash "$FIX_SCRIPT" "$FIXTURES/cjk-emphasis-wrong.org"

# T9: --in-place on wrong file should fix it
cp "$FIXTURES/cjk-emphasis-wrong.org" "$FIX_TMP/wrong-copy.org"
assert_exit 0 "fix: --in-place corrects wrong file" \
  bash "$FIX_SCRIPT" --in-place "$FIX_TMP/wrong-copy.org"

# T10: Fixed file should pass check
assert_exit 0 "fix: corrected file passes check" \
  bash "$CHECK_SCRIPT" "$FIX_TMP/wrong-copy.org"

# T11: --in-place on mixed file should only fix non-block lines
cp "$FIXTURES/cjk-emphasis-mixed.org" "$FIX_TMP/mixed-copy.org"
assert_exit 0 "fix: --in-place on mixed file succeeds" \
  bash "$FIX_SCRIPT" --in-place "$FIX_TMP/mixed-copy.org"

# T12: Fixed mixed file should pass check (src block content was ignored)
assert_exit 0 "fix: corrected mixed file passes check" \
  bash "$CHECK_SCRIPT" "$FIX_TMP/mixed-copy.org"

# T13: Verify src block content was NOT modified
SRC_BLOCK_CONTENT=$(sed -n '/#+BEGIN_SRC python/,/#+END_SRC/p' "$FIX_TMP/mixed-copy.org")
if echo "$SRC_BLOCK_CONTENT" | grep -q '结果：=lto1='; then
  PASS=$((PASS + 1))
  if $VERBOSE; then
    echo -e "[TEST] fix: src block content preserved ... ${GREEN}PASS${NC}"
  fi
else
  FAIL=$((FAIL + 1))
  echo -e "${RED}FAIL${NC}: fix: src block content preserved"
  echo "  Source block content was modified:"
  echo "$SRC_BLOCK_CONTENT"
fi

# T14: --diff on wrong file should produce unified diff
assert_contains '@@' "fix: --diff produces unified diff" \
  bash "$FIX_SCRIPT" --diff "$FIXTURES/cjk-emphasis-wrong.org"

# ---- Results ----

echo ""
echo "========================================"
TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}All $TOTAL test(s) passed${NC}"
else
  echo -e "${RED}$FAIL of $TOTAL test(s) FAILED${NC}"
fi
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
