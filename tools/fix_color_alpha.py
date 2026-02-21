"""Fix Flutter Color alpha helpers.

This repo currently mixes:
- `.withOpacity(x)` (deprecated)
- `.withValues(alpha: (x * 255))` (wrong in modern Flutter; alpha is 0..1)

This script updates Dart files under `mobile/lib` only:
- `.withOpacity(expr)` -> `.withValues(alpha: expr)`
- `.withValues(alpha: (expr * 255))` -> `.withValues(alpha: expr)`

It is intentionally conservative and will skip weird/nested expressions.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

# Matches: .withOpacity(0.2) / .withOpacity(someExpr)
WITH_OPACITY = re.compile(r"\.withOpacity\(\s*(?P<expr>[^)]+?)\s*\)")

# Matches: .withValues(alpha: (0.2 * 255)) with flexible whitespace + optional 255.0
# Very intentionally does NOT try to parse nested parentheses; it targets the current code style.
WITH_VALUES_ALPHA_255 = re.compile(
    r"withValues\(\s*alpha\s*:\s*\(\s*(?P<expr>[^()]+?)\s*\*\s*255(?:\.0)?\s*\)\s*\)"
)


def _apply(text: str) -> tuple[str, int]:
    replacements = 0

    def repl_with_opacity(m: re.Match[str]) -> str:
        nonlocal replacements
        expr = m.group("expr").strip()
        replacements += 1
        return f".withValues(alpha: {expr})"

    def repl_alpha_255(m: re.Match[str]) -> str:
        nonlocal replacements
        expr = m.group("expr").strip()
        replacements += 1
        return f"withValues(alpha: {expr})"

    text2 = WITH_OPACITY.sub(repl_with_opacity, text)
    text3 = WITH_VALUES_ALPHA_255.sub(repl_alpha_255, text2)
    return text3, replacements


def main() -> int:
    if not LIB.exists():
        raise SystemExit(f"Expected {LIB} to exist")

    total_replacements = 0
    changed_files = 0

    for path in LIB.rglob("*.dart"):
        original = path.read_text(encoding="utf-8")
        updated, n = _apply(original)
        if n and updated != original:
            path.write_text(updated, encoding="utf-8")
            total_replacements += n
            changed_files += 1

    print(f"Updated {changed_files} files; {total_replacements} replacements")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
