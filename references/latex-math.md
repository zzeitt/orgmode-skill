# LaTeX Math in Org-mode

## Overview

Org-mode renders LaTeX math via `$...$` (inline) and `\[...\]` (display). All LaTeX
commands (`\log`, `\frac`, `\operatorname`, `\infty`, etc.) MUST be inside these
delimiters — naked `\command` in body text will NOT render.

## Inline Math

```org
$\operatorname{atanh}(x) = \frac{1}{2}\log\frac{1+|x|}{1-|x|}$
$x \mapsto (\operatorname{sgn}, |x|)$
$|x| \ge 1$, $|x| < 2^{-28}$
$\pm\infty$
```

## Display Math

```org
\[
\log(1+t) = t - \frac{t^2}{2} + \frac{t^3}{3} - \cdots
\]
```

## Common Pitfalls

### Unwrapped LaTeX (WRONG)

```org
恒等式 \operatorname{atanh}(x)=\frac{1}{2}\bigl(\log(1+|x|)-\log(1-|x|)\bigr)。
```

The `\operatorname`, `\frac`, `\bigl`, `\log` commands are outside `$...$` → won't render.

### Correctly Wrapped

```org
恒等式 $\operatorname{atanh}(x)=\frac{1}{2}\bigl(\log(1+|x|)-\log(1-|x|)\bigr)$。
```

### Partial Wrapping (WRONG)

```org
$\operatorname{atanh}($x)=$\frac{1}{2}\bigl($...$)$
```

Each `$` toggles math mode. This creates 3 tiny math blocks instead of one continuous
expression. Wrap the entire mathematical expression as one unit.

### Table Cells

Every table cell that contains LaTeX needs its own `$...$`:

```org
| x_abs = 1    | $\pm\infty$          | sign OR 0x7FF... |
| x_abs $\le$ 0.15 | 0.5*log1p(...)   | libm log1p       |
```

### Chinese Text Adjacent to Math

**Important**: org-mode inline math delimiters `$...$` have boundary requirements
similar to emphasis markers (`*`, `/`, `~`, `=`). The opening `$` must be preceded by
whitespace, `-`, `(`, `'`, `"`, or line start. CJK characters (both CJK ideographs and
full-width punctuation `：，。；！？、（）`) are NOT in this allowed set, so `$...$`
touching CJK text without an intervening space will fail to render:

```org
对$x \ge 1$（含$\pm\infty$）返回 NaN。    ← WRONG: $ won't render
对 $x \ge 1$ (含 $\pm\infty$) 返回 NaN。  ← OK: space before/after $
```

**Rule**: always insert a space between `$` delimiters and adjacent CJK
characters or CJK punctuation. ASCII punctuation (`.` `,` `;` `?` etc.) after the
closing `$` is fine and does not need extra spacing:

```org
$x > 0$时…        ← WRONG: CJK char after $
$x > 0$ 时…       ← OK: space before CJK
$x > 0$, 即…      ← OK: ASCII comma after $ needs no space
```

## Checking for Unwrapped LaTeX

Use the bundled script:

```bash
# Check a local file
bash ~/.claude/skills/orgmode/scripts/check-org-latex.sh file.org

# For zt.dell files, download first, then check:
ssh zt.dell "type \"D:\\path\\to\\file.org\"" > /tmp/file.org
bash ~/.claude/skills/orgmode/scripts/check-org-latex.sh /tmp/file.org
```

The script uses Emacs `org-element-context` to reliably detect LaTeX commands outside
math delimiters. More accurate than regex-based approaches because it understands
org-mode's AST structure (source blocks, verbatim, tables, etc.).

## Common LaTeX Commands in Math Documents

| Command | Meaning | Example |
|---------|---------|---------|
| `\log` | Logarithm | `$\log(1+x)$` |
| `\frac{a}{b}` | Fraction | `$\frac{1}{2}$` |
| `\operatorname{name}` | Operator name | `$\operatorname{atanh}(x)$` |
| `\infty` | Infinity | `$\pm\infty$` |
| `\pm` | Plus-minus | `$\pm 1$` |
| `\inf` | Infimum (or infinity shorthand) | `$\pm\inf$` |
| `\ge` / `\le` | Greater/less-or-equal | `$|x| \ge 1$` |
| `\bigl(` / `\bigr)` | Sized parentheses | `$\bigl(\log(1+x)\bigr)$` |
| `\cdot` | Multiplication dot | `$a \cdot b$` |
| `\text{...}` | Roman text in math | `$\text{lo} + \text{hi}$` |
| `\mapsto` | Maps to | `$x \mapsto y$` |
| `\in` | Set membership | `$x \in [a, b)$` |
| `\to` | Tends to | `$x \to \infty$` |
| `\sim` | Similar/asymptotic | `$\sim 3$ cycles` |
