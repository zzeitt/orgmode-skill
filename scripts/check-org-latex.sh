#!/bin/bash
# Check an org-mode file for LaTeX commands not wrapped in $...$ or \[...\]
# Usage: check-org-latex.sh <file.org>
#
# Uses Emacs batch mode with org-element-context to reliably detect
# unwrapped LaTeX fragments. Much more reliable than regex-based approaches.

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: check-org-latex.sh <file.org>"
  echo "Check an org-mode file for unwrapped LaTeX math commands."
  exit 1
fi

emacs --batch --eval "
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
              (unless (eq (org-element-type context) 'latex-fragment)
                (setq unwrapped (1+ unwrapped))
                (princ (format \"Line %d col %d: %s\n\"
                               (line-number-at-pos pos)
                               (- pos (line-beginning-position))
                               (match-string 0)))))))))
    (if (= unwrapped 0)
        (princ \"OK: All LaTeX commands are wrapped in math delimiters\n\")
      (princ (format \"FAIL: %d unwrapped LaTeX command(s) found\n\" unwrapped))
      (kill-emacs 1)))))" \
  2>&1
