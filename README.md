# orgmode-skill

Org-mode syntax knowledge and validation scripts for writing `.org` files.

## Structure

```
├── SKILL.md                  # Skill entry point (quick reference)
├── references/               # Detailed syntax references
│   ├── org-syntax.md         # Core org-mode syntax
│   ├── latex-math.md         # LaTeX math formatting & CJK boundary rules
│   ├── properties.md         # Property drawers
│   ├── timestamps.md         # Date/time formats
│   ├── links.md              # Internal/external links
│   └── examples.md           # Real-world formatting patterns
├── scripts/                  # Validation & correction tools
│   ├── check-org-cjk-emphasis.sh   # Detect CJK touching $ = ~ + delimiters
│   ├── check-org-latex.sh          # Detect unwrapped LaTeX commands (requires Emacs)
│   └── fix-org-cjk-emphasis.sh     # Auto-correct CJK-delimiter spacing
└── tests/
    ├── fixtures/             # Known-good and known-bad .org files
    └── test-check-fix.sh     # Unit test harness
```

## Scripts

### `check-org-cjk-emphasis.sh`

Check an org file for markup delimiters (`*`, `/`, `_`, `=`, `~`, `+`, `$`) touching
CJK characters without whitespace boundary. These will fail to render in org-mode.

```bash
bash scripts/check-org-cjk-emphasis.sh file.org
# OK: No CJK characters touching markup delimiters
# FAIL: CJK characters touching markup delimiters (won't render): ...
```

Skips content inside `#+BEGIN_SRC` / `#+END_SRC` blocks.

### `fix-org-cjk-emphasis.sh`

Auto-fix CJK-delimiter spacing issues:

```bash
bash scripts/fix-org-cjk-emphasis.sh file.org              # dry-run
bash scripts/fix-org-cjk-emphasis.sh --diff file.org       # unified diff
bash scripts/fix-org-cjk-emphasis.sh --in-place file.org   # apply fixes
```

### `check-org-latex.sh`

Detect LaTeX commands outside `$...$` / `\[...\]` delimiters. Requires Emacs.

```bash
bash scripts/check-org-latex.sh file.org
```

## Running Tests

```bash
bash tests/test-check-fix.sh     # run all tests
bash tests/test-check-fix.sh -v  # verbose output
```

Tests cover:
- Detection of all delimiter types (`*`, `/`, `_`, `=`, `~`, `+`, `$`) touching CJK
- Source block content exclusion
- Auto-correction produces valid output
- Correction is idempotent (fixed file passes check)

## CJK Boundary Rule

Org-mode delimiters (`*`, `/`, `_`, `=`, `~`, `+`, `$`) require whitespace or ASCII
punctuation as boundaries. CJK characters (U+3000–U+303F, U+4E00–U+9FFF, U+FF00–U+FFEF)
are NOT valid boundaries:

```org
结果：=lto1=     ← WRONG: CJK colon touches = (won't render)
结果： =lto1=    ← OK: space between delimiter and CJK
对$x$测试       ← WRONG: CJK touches $ (won't render)
对 $x$ 测试     ← OK: spaces around $
/方案 A/：回退  ← WRONG: italic / touches CJK colon
/ 方案 A/ ：回退 ← OK: space between / and CJK
```

## References

Derived from [majorgreys/claude-orgmode](https://github.com/majorgreys/claude-orgmode/tree/master/skills/orgmode) — the original org-mode skill providing core syntax references (headings, lists, links, properties, timestamps, examples).

Additions in this fork:
- **CJK boundary rules** for emphasis (`*`, `/`, `_`, `=`, `~`, `+`) and math (`$`) delimiters
- **`check-org-cjk-emphasis.sh`** — detect CJK touching markup delimiters
- **`fix-org-cjk-emphasis.sh`** — auto-correct CJK-delimiter spacing (dry-run / diff / in-place)
- **Unit tests** with deterministic fixtures and GitHub Actions CI

## License

MIT
