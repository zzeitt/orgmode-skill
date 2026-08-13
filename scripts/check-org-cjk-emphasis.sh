#!/bin/bash
# Check an org-mode file for markup delimiters (*, /, _, =, ~, +, $) touching CJK
# characters without whitespace boundary. These will fail to render in org-mode.
#
# Usage: check-org-cjk-emphasis.sh <file.org>

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: check-org-cjk-emphasis.sh <file.org>"
  echo "Detect * / _ = ~ + \$ delimiters touching CJK characters (fontlock will fail)."
  exit 1
fi

# Use perl to track source-block state and find CJK-delimiter boundary violations.
# Output format: "line_num:text" for each match, mimicking grep -n output.
matches=$(perl -CSD -ne '
  BEGIN { $in_block = 0 }

  if (/^[ \t]*#\+BEGIN_SRC/)  { $in_block = 1; }
  if (/^[ \t]*#\+END_SRC/)    { $in_block = 0; }

  if (!$in_block && !/^[ \t]*#\+RESULTS/) {
    my $cjk   = qr/[\x{3000}-\x{303f}\x{4e00}-\x{9fff}\x{ff00}-\x{ffef}]/;
    my $delim = qr/[\*\/_=\~\+\$]/;

    if (/($cjk)($delim)/ || /($delim)($cjk)/) {
      printf "%d:%s", $., $_;
    }
  }
' "$FILE" 2>/dev/null || true)

if [ -z "$matches" ]; then
  echo "OK: No CJK characters touching markup delimiters (*, /, _, =, ~, +, \$)"
else
  echo "FAIL: CJK characters touching markup delimiters (won't render):"
  echo "$matches"
  echo ""
  echo "Fix: add a space between * / _ = ~ + \$ markers and CJK characters."
  echo "  =中文=  → = 中文 ="
  echo "  /中文/  → / 中文 /"
  echo "  \$x\$中  → \$x\$ 中"
  echo "  结果：=lto1= → 结果： =lto1="
  exit 1
fi
