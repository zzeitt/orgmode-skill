#!/bin/bash
# Check an org-mode file for markup delimiters (*, /, _, =, ~, +, $) whose OUTER
# boundary touches CJK characters without whitespace. These will fail to render in
# org-mode.
#
# Only the OUTER boundary matters: the space between the emphasis marker and the
# surrounding CJK text. The marker stays tight against its own emphasis content
# (e.g. /方案/ is correct; /方案/： needs a space before ：).
#
# Usage: check-org-cjk-emphasis.sh <file.org>

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: check-org-cjk-emphasis.sh <file.org>"
  echo "Detect * / _ = ~ + \$ delimiters touching CJK at their outer boundary."
  exit 1
fi

# Track pairing per delimiter type: the first occurrence opens emphasis, the next
# closes it. On OPEN we flag CJK immediately before (surrounding side); on CLOSE we
# flag CJK immediately after. CJK inside the emphasis (its own content) is fine.
matches=$(perl -CSD - "$FILE" <<'PERL' 2>/dev/null || true
  my $cjk   = qr/[\x{3000}-\x{303f}\x{4e00}-\x{9fff}\x{ff00}-\x{ffef}]/;
  my $delim = qr/[\*\/_=\~\+\$]/;
  my $in_block = 0;
  while (<>) {
    if (/^[ \t]*#\+BEGIN_SRC/)  { $in_block = 1; next; }
    if (/^[ \t]*#\+END_SRC/)    { $in_block = 0; next; }
    next if $in_block || /^[ \t]*#\+RESULTS/;

    chomp;
    my @c = split //, $_;
    my %inside;
    my $violation = 0;
    for (my $i = 0; $i < @c; $i++) {
      my $ch = $c[$i];
      next unless $ch =~ $delim;
      my $prev = $i > 0 ? $c[$i-1] : "";
      my $next = $i < @c-1 ? $c[$i+1] : "";
      if (!$inside{$ch}) {          # opening marker
        $violation = 1, last if $prev =~ $cjk;
        $inside{$ch} = 1;
      } else {                      # closing marker
        $violation = 1, last if $next =~ $cjk;
        $inside{$ch} = 0;
      }
    }
    if ($violation) { printf "%d:%s\n", $., $_; }
  }
PERL
)

if [ -z "$matches" ]; then
  echo "OK: No CJK characters touching markup delimiters (*, /, _, =, ~, +, \$)"
else
  echo "FAIL: CJK characters touching markup delimiters at outer boundary (won't render):"
  echo "$matches"
  echo ""
  echo "Fix: add a space between the delimiter and the surrounding CJK text (NOT"
  echo "between the delimiter and its own emphasis content)."
  echo "  代码=code=示例 → 代码 =code= 示例"
  echo "  /方案 A/：回退 → /方案 A/ ：回退"
  echo "  对\$x\$测试    → 对 \$x\$ 测试"
  exit 1
fi
