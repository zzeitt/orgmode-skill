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
│   ├── check-org-markup.sh         # Detect CJK-touching delimiters, **bold**, heading space
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

1. **cjk-boundary** — a delimiter (`*` `/` `_` `=` `~` `+` `$`) touching CJK at its
   outer boundary (won't render).
2. **markdown-bold** — `**bold**` should be `*bold*`.
3. **heading-space** — a heading marker `*Title` should be `* Title`.

```bash
bash scripts/check-org-markup.sh file.org                 # detect
bash scripts/fix-org-markup.sh file.org                   # dry-run
bash scripts/fix-org-markup.sh --in-place file.org        # apply fixes
```

Skips content inside `#+BEGIN_SRC` / `#+END_SRC` blocks (case-insensitive).

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
- Detection of all delimiter types (`*`, `/`, `_`, `=`, `~`, `+`, `$`) touching CJK
- Markdown-bold detection and conversion to single asterisks
- Heading-missing-space detection and fix
- Source block content exclusion
- Auto-correction produces valid output
- Correction is idempotent (fixed file passes check)

## CJK Boundary Rule

Org-mode delimiters (`*`, `/`, `_`, `=`, `~`, `+`, `$`) require whitespace or ASCII
punctuation at their **outer boundary**. CJK characters (U+3000–U+303F, U+4E00–U+9FFF,
U+FF00–U+FFEF) are NOT valid boundaries:

```org
结果：=lto1=      ← WRONG: CJK colon touches = (won't render)
结果： =lto1=     ← OK: space between delimiter and CJK
对$x$测试        ← WRONG: CJK touches $ (won't render)
对 $x$ 测试      ← OK: spaces around $
/方案 A/：回退   ← WRONG: italic / touches CJK colon after closing
/方案 A/ ：回退  ← OK: content tight, space only before CJK colon
```

**The space goes only on the OUTER boundary** — between the marker and surrounding CJK
text — never between the marker and its own content. `*重点*`, `/方案 A/`, `=code=`,
`_强调_` stay tight; only the surrounding CJK side gets a space.

## References

Derived from [majorgreys/claude-orgmode](https://github.com/majorgreys/claude-orgmode/tree/master/skills/orgmode) — the original org-mode skill providing core syntax references (headings, lists, links, properties, timestamps, examples).

Additions in this fork:
- **CJK boundary rules** for emphasis (`*`, `/`, `_`, `=`, `~`, `+`) and math (`$`) delimiters
- **`check-org-cjk-emphasis.sh`** — detect CJK touching markup delimiters
- **`fix-org-cjk-emphasis.sh`** — auto-correct CJK-delimiter spacing (dry-run / diff / in-place)
- **Unit tests** with deterministic fixtures and GitHub Actions CI

## License

MIT
