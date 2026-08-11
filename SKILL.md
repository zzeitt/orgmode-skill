---
name: orgmode
description: |
  Org-mode syntax and formatting knowledge. Reference docs for headings, lists, links, properties, timestamps, and other org-mode constructs.

  Triggers: org-mode, .org files, org syntax, org formatting, org properties, org timestamps, LaTeX math, org latex
---

# Org-mode Syntax Skill

Pure org-mode knowledge for writing and formatting `.org` files. No emacsclient or Emacs daemon required.

For org-roam or vulpea note management (creating notes, searching, linking), use the **org-roam** or **vulpea** skills instead.

## Quick Reference

### Headings

```org
* Top-level heading
** Second level
*** Third level
```

### Text Formatting

```org
*bold* /italic/ _underline_ ~code~ =verbatim= +strikethrough+
```

### Lists

```org
- Unordered item
  - Nested item
1. Ordered item
2. Second item
- [ ] Checkbox unchecked
- [X] Checkbox checked
```

### Links

```org
[[https://example.com][Description]]
[[file:path/to/file.org][File link]]
[[id:uuid-here][ID link]]
```

### Properties

```org
:PROPERTIES:
:ID:       some-uuid
:CUSTOM:   value
:END:
```

### Keywords

```org
#+TITLE: Document Title
#+FILETAGS: :tag1:tag2:
#+DATE: [2026-03-01 Sun]
#+AUTHOR: Name
```

### Timestamps

```org
<2026-03-01 Sun>          Active timestamp
[2026-03-01 Sun]          Inactive timestamp
<2026-03-01 Sun 10:00>    With time
SCHEDULED: <2026-03-01 Sun>
DEADLINE: <2026-03-05 Thu>
```

### Source Blocks

```org
#+BEGIN_SRC python
def hello():
    print("Hello")
#+END_SRC
```

### Tables

```org
| Name  | Value |
|-------+-------|
| Alice |    42 |
| Bob   |    17 |
```

## Tag Constraints

Org-mode tags **cannot contain hyphens**. Use underscores instead:
- Invalid: `my-tag`, `web-dev`
- Valid: `my_tag`, `web_dev`

### LaTeX Math

```org
Inline: $\operatorname{atanh}(x) = \frac{1}{2}\log\frac{1+|x|}{1-|x|}$
Display: \[ \log(1+t) = t - \frac{t^2}{2} + \frac{t^3}{3} - \cdots \]
```

All `\` commands (`\log`, `\frac`, `\operatorname`, `\infty`, etc.) MUST be inside
`$...$` or `\[...\]` — naked `\command` in body text will NOT render. Wrap the entire
mathematical expression as one unit; avoid splitting across multiple `$...$` pairs.

**Validation script**: `scripts/check-org-latex.sh <file.org>` — Uses Emacs
`org-element-context` to detect unwrapped LaTeX commands with AST-level accuracy.

The `$` inline math delimiter follows boundary rules similar to emphasis markers:
CJK characters touching `$` without whitespace will prevent rendering.

**Validation scripts**:
| Script | Purpose |
|--------+---------|
| `scripts/check-org-cjk-emphasis.sh <file.org>` | Check `$`/`=`/`~`/`+` touching CJK (detection only) |
| `scripts/fix-org-cjk-emphasis.sh [--in-place\|--diff] <file.org>` | Auto-fix CJK-delimiter spacing |

> See **latex-math.md** for common pitfalls, examples, and command reference.

## Detailed References

- **org-syntax.md** - Complete org-mode syntax reference
- **properties.md** - Property drawers, node properties, and inheritance
- **timestamps.md** - Date/time formats, scheduling, deadlines, repeaters
- **links.md** - Internal links, external links, ID links, file links
- **latex-math.md** - LaTeX math formatting, common pitfalls, check script
- **examples.md** - Common formatting patterns and best practices
