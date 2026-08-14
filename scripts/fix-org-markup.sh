#!/bin/bash
# Fix common org-mode markup pitfalls:
#   1. cjk-boundary  — insert a space at the OUTER boundary of a markup delimiter
#                      (* / _ = ~ + $) touching CJK text (not inside the emphasis).
#   2. markdown-bold — **X** → *X* (org uses single asterisks for bold).
#   3. heading-space — *Title → * Title (headline markers need a space).
#
# Usage:
#   fix-org-markup.sh <file.org>            dry-run: show what would change
#   fix-org-markup.sh --in-place <file.org>  apply fixes in-place
#   fix-org-markup.sh --diff <file.org>      show unified diff (no changes)
#
# Operates on a single file. For batch processing, use with find/xargs:
#   find . -name '*.org' -exec fix-org-markup.sh --in-place {} \;

set -uo pipefail

IN_PLACE=false
DIFF_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --in-place) IN_PLACE=true; shift ;;
    --diff)     DIFF_MODE=true; shift ;;
    *)          break ;;
  esac
done

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: fix-org-markup.sh [--in-place|--diff] <file.org>"
  echo ""
  echo "  (default)   Dry-run: show lines that would be changed"
  echo "  --diff      Show unified diff without modifying"
  echo "  --in-place  Apply fixes directly to the file"
  echo ""
  echo "Fixes cjk-boundary, markdown-bold, and heading-space pitfalls."
  echo "Skips lines inside #+BEGIN_SRC / #+END_SRC blocks."
  exit 1
fi

FIXED=$(mktemp)
trap 'rm -f "$FIXED"' EXIT

perl -CSD - "$FILE" > "$FIXED" <<'PERL'
  my $cjk   = qr/[\x{3000}-\x{303f}\x{4e00}-\x{9fff}\x{ff00}-\x{ffef}]/;
  my $delim = qr/[\*\/_=\~\+\$]/;
  my $in_block = 0;
  while (<>) {
    if (/^[ \t]*#\+BEGIN_SRC/i)  { $in_block = 1; print; next; }
    if (/^[ \t]*#\+END_SRC/i)    { $in_block = 0; print; next; }
    if ($in_block || /^[ \t]*#\+RESULTS/) { print; next; }

    chomp;
    my $line = $_;

    # 1. Markdown bold → org bold: **X** → *X*
    $line =~ s/\*\*([^*]+)\*\*/*$1*/g;

    # 2. Heading missing space: ^*+ non-space with no other * → add space after stars
    if ($line =~ /^(\*+)([^ \t*])/ && substr($line, length($1)) !~ /\*/) {
      $line =~ s/^(\*+)/$1 /;
    }

    # 3. CJK boundary (pairing state machine per delimiter type)
    my @c = split //, $line;
    my %inside;
    my $out = "";
    for (my $i = 0; $i < @c; $i++) {
      my $ch = $c[$i];
      if ($ch =~ $delim) {
        my $prev = $i > 0 ? $c[$i-1] : "";
        my $next = $i < @c-1 ? $c[$i+1] : "";
        if (!$inside{$ch}) {         # opening marker
          $out .= " " if $prev =~ $cjk;
          $out .= $ch;
          $inside{$ch} = 1;
        } else {                     # closing marker
          $out .= $ch;
          $out .= " " if $next =~ $cjk;
          $inside{$ch} = 0;
        }
      } else {
        $out .= $ch;
      }
    }
    print "$out\n";
  }
PERL

# Check if anything changed
if cmp -s "$FILE" "$FIXED"; then
  echo "OK: No markup pitfalls in $FILE"
  exit 0
fi

if $DIFF_MODE; then
  diff -u "$FILE" "$FIXED" || true
elif $IN_PLACE; then
  CHANGES=$(diff "$FILE" "$FIXED" | grep '^<' | wc -l)
  cp "$FIXED" "$FILE"
  echo "Fixed $CHANGES line(s) in $FILE"
else
  # Dry-run: show before/after for changed lines
  echo "Lines that would be changed:"
  echo "============================"
  diff "$FILE" "$FIXED" | grep -P '^[<>]' | while IFS= read -r line; do
    if [[ "$line" == \<* ]]; then
      echo "  - ${line:2}"
    else
      echo "  + ${line:2}"
    fi
  done
  echo ""
  CHANGES=$(diff "$FILE" "$FIXED" | grep '^<' | wc -l)
  echo "Dry-run: $CHANGES line(s) would be changed."
  echo "Run with --in-place to apply, or --diff to see a unified diff."
fi
