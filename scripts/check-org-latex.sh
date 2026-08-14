#!/bin/bash
# Check an org-mode file for LaTeX pitfalls:
#   1. nested environment — \begin{...} nested inside a \[...\] display fragment.
#      Use a standalone environment (\begin{align}…\end{align}) instead.
#   2. unwrapped command — a LaTeX \command outside $...$ / \[...\].
#
# Usage: check-org-latex.sh <file.org>
#
# Check 1 uses perl (no dependencies). Check 2 uses Emacs batch mode with
# org-element-context for AST-level accuracy; it is skipped if Emacs is absent.

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: check-org-latex.sh <file.org>"
  echo "Check for nested LaTeX environments and unwrapped LaTeX commands."
  exit 1
fi

rc=0

# ---- Check 1: \begin{...} nested inside \[...\] (perl) ----
nested=$(perl -CSD - "$FILE" <<'PERL' 2>/dev/null || true
  my $in = 0;
  my $n  = 0;
  while (<>) {
    if (!$in && /\\\[/) { $in = 1; }
    if ($in && /\\begin\{/) {
      printf "Line %d: \\begin{...} nested inside \\[...\\] — use a standalone \\begin{align}…\\end{align}\n", $.;
      $n++;
    }
    if ($in && /\\\]/) { $in = 0; }
  }
  exit 0;
PERL
)

if [ -n "$nested" ]; then
  echo "$nested"
  rc=1
fi

# ---- Check 2: unwrapped LaTeX commands (Emacs) ----
if command -v emacs >/dev/null 2>&1; then
  unwrapped=$(emacs --batch --eval "
(progn
  (require 'org)
  (find-file \"$FILE\")
  (goto-char (point-min))
  (let ((unwrapped 0))
    (while (re-search-forward \"\\\\\\\\[a-zA-Z]+\" nil t)
      (let ((pos (match-beginning 0)))
        (save-excursion
          (save-match-data
            (let ((context (org-element-context)))
              (unless (memq (org-element-type context) '(latex-fragment latex-environment))
                (setq unwrapped (1+ unwrapped))
                (princ (format \"Line %d col %d: %s\n\"
                               (line-number-at-pos pos)
                               (- pos (line-beginning-position))
                               (match-string 0)))))))))
    (if (= unwrapped 0)
        (princ \"OK: all LaTeX commands wrapped in math delimiters\n\")
      (princ (format \"FAIL: %d unwrapped LaTeX command(s) found\n\" unwrapped))
      (kill-emacs 1)))))" \
    2>&1) || true

  if echo "$unwrapped" | grep -q 'FAIL:'; then
    echo "$unwrapped"
    rc=1
  elif [ "$rc" -eq 0 ]; then
    # Only print the OK line if check 1 also passed
    echo "$unwrapped"
  fi
else
  echo "(skipped unwrapped-command check: emacs not found)"
fi

if [ "$rc" -eq 0 ] && [ -z "$nested" ]; then
  echo "OK: No LaTeX pitfalls"
fi

exit "$rc"
