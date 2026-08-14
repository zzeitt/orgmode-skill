#!/bin/bash
# Check an org-mode file for common markup pitfalls:
#   1. cjk-boundary  — a markup delimiter (* / _ = ~ + $) whose OUTER boundary touches
#                      CJK text (fails to render in org-mode).
#   2. markdown-bold — Markdown **bold** instead of org *bold*.
#   3. heading-space — a heading marker (*+) missing the space before its title.
#
# Usage: check-org-markup.sh <file.org>

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: check-org-markup.sh <file.org>"
  echo "Detect cjk-boundary, markdown-bold, and heading-space markup pitfalls."
  exit 1
fi

matches=$(perl -CSD - "$FILE" <<'PERL' 2>/dev/null || true
  my $cjk   = qr/[\x{3000}-\x{303f}\x{4e00}-\x{9fff}\x{ff00}-\x{ffef}]/;
  my $delim = qr/[\*\/_=\~\+\$]/;
  my $in_block = 0;
  while (<>) {
    if (/^[ \t]*#\+BEGIN_SRC/i)  { $in_block = 1; next; }
    if (/^[ \t]*#\+END_SRC/i)    { $in_block = 0; next; }
    next if $in_block || /^[ \t]*#\+RESULTS/;

    chomp;
    my $line = $_;
    my @issues;

    # 1. Markdown bold: **X** should be *X*
    if ($line =~ /\*\*[^*]+\*\*/) { push @issues, "markdown-bold"; }

    # 2. Heading missing space: ^*+ non-space, with no other * in the rest of the line
    if ($line =~ /^(\*+)([^ \t*])/ && substr($line, length($1)) !~ /\*/) {
      push @issues, "heading-space";
    }

    # 3. CJK boundary (pairing state machine per delimiter type)
    my @c = split //, $line;
    my %inside;
    my $cjk_violation = 0;
    for (my $i = 0; $i < @c; $i++) {
      my $ch = $c[$i];
      next unless $ch =~ $delim;
      my $prev = $i > 0 ? $c[$i-1] : "";
      my $next = $i < @c-1 ? $c[$i+1] : "";
      if (!$inside{$ch}) {          # opening marker
        $cjk_violation = 1, last if $prev =~ $cjk;
        $inside{$ch} = 1;
      } else {                      # closing marker
        $cjk_violation = 1, last if $next =~ $cjk;
        $inside{$ch} = 0;
      }
    }
    push @issues, "cjk-boundary" if $cjk_violation;

    if (@issues) { printf "%d:%s  [%s]\n", $., $line, join(",", @issues); }
  }
PERL
)

if [ -z "$matches" ]; then
  echo "OK: No markup pitfalls found"
else
  echo "FAIL: markup pitfalls (won't render correctly):"
  echo "$matches"
  echo ""
  echo "Fix:"
  echo "  cjk-boundary:  add a space at the OUTER boundary of the delimiter (not inside)."
  echo "  markdown-bold: **X** → *X* (org uses single asterisks)."
  echo "  heading-space: **Title → ** Title (headline markers need a space)."
  exit 1
fi
