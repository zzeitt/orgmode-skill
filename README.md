# orgmode-skill

Org-mode syntax knowledge and validation scripts for writing `.org` files.

## Structure

```
├── SKILL.md                  # Skill entry point (quick reference)
├── references/               # Detailed syntax references
│   ├── org-syntax.md         # Core org-mode syntax
│   ├── latex-math.md         # LaTeX math formatting & non-ASCII boundary rules
│   ├── properties.md         # Property drawers
│   ├── timestamps.md         # Date/time formats
│   ├── links.md              # Internal/external links
│   └── examples.md           # Real-world formatting patterns
├── scripts/                  # Validation & correction tools
│   ├── check-org-markup.sh         # Detect non-ASCII-touching delimiters, **bold**, heading space
│   ├── fix-org-markup.sh           # Auto-fix the above
│   ├── check-org-latex.sh          # Detect nested env + unwrapped LaTeX (requires Emacs)
│   └── bump-version.sh             # Semver bump
└── tests/
    ├── fixtures/             # Known-good and known-bad .org files
    └── test-check-fix.sh     # Unit test harness
```

## Scripts

### `check-org-markup.sh` / `fix-org-markup.sh`

Detect and fix three markup pitfalls:

1. **cjk-boundary** — a delimiter (`*` `/` `_` `=` `~` `+` `$`) touching a **non-ASCII
   character** at its outer boundary (won't render): CJK, fullwidth punctuation, but
   also `——` (U+2014), `……` (U+2026), `·` (U+00B7), curly quotes.
2. **markdown-bold** — `**bold**` should be `*bold*`.
3. **heading-space** — a heading marker `*Title` should be `* Title`.

```bash
bash scripts/check-org-markup.sh file.org                 # detect
bash scripts/fix-org-markup.sh file.org                   # dry-run
bash scripts/fix-org-markup.sh --in-place file.org        # apply fixes
bash scripts/fix-org-markup.sh --spaces --in-place file.org  # keep $…$, insert spaces
```

For `$...$` touching non-ASCII, the fixer converts to `\(...\)` by default — that
delimiter has no boundary restriction and avoids inserted spaces in CJK prose.
`--spaces` restores the old behaviour of inserting spaces around `$`.

Skips content inside `#+BEGIN_SRC` / `#+END_SRC` blocks (case-insensitive). Escaped
`\$` is treated as a literal dollar sign, not math.

### `check-org-latex.sh`

Detect LaTeX pitfalls: `\begin{…}` nested inside `\[…\]` (use a standalone environment)
and LaTeX commands outside `$...$` / `\[...\]`. The unwrapped-command check requires
Emacs; the nested-environment check does not.

```bash
bash scripts/check-org-latex.sh file.org
```

## Running Tests

```bash
bash tests/test-check-fix.sh     # run all tests
bash tests/test-check-fix.sh -v  # verbose output
```

Tests cover:
- Detection of all delimiter types (`*`, `/`, `_`, `=`, `~`, `+`, `$`) touching
  non-ASCII characters (CJK, fullwidth punctuation, em dash, ellipsis, middle dot)
- Markdown-bold detection and conversion to single asterisks
- Heading-missing-space detection and fix
- `$…$` → `\(…\)` conversion by default, and `--spaces` alternate behaviour
- Escaped `\$` left untouched
- Source block content exclusion
- Auto-correction produces valid output
- Correction is idempotent (fixed file passes check)

## Non-ASCII Boundary Rule

Org-mode delimiters (`*`, `/`, `_`, `=`, `~`, `+`, `$`) require whitespace or an
ASCII boundary character at their **outer boundary**. The boundary sets are ASCII-only,
so **any non-ASCII character** is invalid — CJK ideographs and fullwidth punctuation,
but also `——` (U+2014), `……` (U+2026), `·` (U+00B7) and curly quotes:

```org
结果：=foo=      ← WRONG: CJK colon touches = (won't render)
结果： =foo=     ← OK: space between delimiter and CJK
对$x$测试        ← WRONG: CJK touches $ (won't render)
对\(x\)测试      ← OK: \(…\) has no boundary restriction
对 $x$ 测试      ← OK (alternative): spaces around $
/方案 A/：回退   ← WRONG: italic / touches CJK colon after closing
/方案 A/ ：回退  ← OK: content tight, space only before CJK colon
可满足——~unsat~  ← WRONG: em dash touches ~ before opening
可满足—— ~unsat~ ← OK: space after em dash
```

**The space goes only on the OUTER boundary** — between the marker and surrounding
non-ASCII text — never between the marker and its own content. `*重点*`, `/方案 A/`,
`=code=`, `_强调_` stay tight; only the surrounding non-ASCII side gets a space.
For inline math, prefer switching `$...$` to `\(...\)` instead of inserting spaces.

## References

Derived from [majorgreys/claude-orgmode](https://github.com/majorgreys/claude-orgmode/tree/master/skills/orgmode) — the original org-mode skill providing core syntax references (headings, lists, links, properties, timestamps, examples).

Additions in this fork:
- **Non-ASCII boundary rules** for emphasis (`*`, `/`, `_`, `=`, `~`, `+`) and math
  (`$`, `\(…\)`) delimiters
- **`check-org-markup.sh`** — detect non-ASCII characters touching markup delimiters
- **`fix-org-markup.sh`** — auto-correct boundaries; converts `$…$` → `\(…\)` by
  default and inserts spaces for emphasis markers (dry-run / diff / in-place)
- **Unit tests** with deterministic fixtures and GitHub Actions CI

## License

MIT
