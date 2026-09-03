#!/usr/bin/env python3
"""PostToolUse(Edit|Write) — enforce the design-token single source of truth.

Rejects hardcoded colors, spacing, radii, type sizes and durations inside
`lib/features/**` and `lib/shared/**`. Those directories must read Layer 2
semantic tokens through `context.*` instead (see CLAUDE.md, rule 1).

`lib/core/design/**` is exempt: that is where literals are *supposed* to live.

Exit 2 returns the findings to Claude so the violation is corrected in the same
turn, which is the whole point -- catching this at review time is too late,
because by then the pattern has already been copied into five more screens.
"""
import json
import os
import re
import sys

# (regex, human explanation) -- each pattern targets a literal in a position
# where a token belongs.
RULES = [
    (re.compile(r"\bColor\(0x[0-9a-fA-F]{6,8}\)"),
     "hardcoded Color(0x...) -> use context.colors.<role>"),
    (re.compile(r"\bColors\.[a-zA-Z]"),
     "Flutter Colors.* -> use context.colors.<role>"),
    (re.compile(r"\bTheme\.of\(context\)\.(colorScheme|textTheme)"),
     "Theme.of(context) -> use context.colors / context.type"),
    # The digit must sit directly after "(" or a "name:"/"," -- so a literal
    # argument is caught, while an expression built from a token
    # (`left: context.sizes.accentEdge * 2`) is not.
    (re.compile(r"\bEdgeInsets\.(all|symmetric|only|fromLTRB)\("
                r"(?:[^)]*?[,:])?\s*-?\d"),
     "literal EdgeInsets -> use context.spacing.<step>"),
    (re.compile(r"\bfontSize:\s*\d"),
     "literal fontSize -> use a context.type.<style>"),
    (re.compile(r"\bBorderRadius\.(circular|all)\(\s*\d"),
     "literal BorderRadius -> use context.radii.<role>"),
    (re.compile(r"\bRadius\.circular\(\s*\d"),
     "literal Radius -> use context.radii.<role>"),
    (re.compile(r"\bDuration\(\s*(milliseconds|seconds)\s*:\s*\d"),
     "literal Duration -> use context.motion.<role>"),
    (re.compile(r"\bSizedBox\((height|width):\s*\d"),
     "literal SizedBox size -> use context.spacing.<step>"),
    (re.compile(r"\bfontWeight:\s*FontWeight\.w?\d"),
     "literal FontWeight -> use a context.type.<style>"),
    (re.compile(r"\bletterSpacing:\s*-?\d"),
     "literal letterSpacing -> use a context.type.<style>"),
    (re.compile(r"\bpackage:scanapp/core/design/tokens/"),
     "primitive tokens imported into UI -> read context.* semantic tokens"),

    # --- rule 1b: style once, in the theme, never at the call site ----------
    (re.compile(r"\b(Filled|Elevated|Outlined|Text|Icon|Segmented)Button"
                r"\.styleFrom\("),
     "button styled at the call site -> set it in AppTheme's "
     "*ButtonThemeData, or add a variant (CLAUDE.md 1b)"),
    (re.compile(r"\bButtonStyle\("),
     "ButtonStyle at the call site -> belongs in AppTheme (CLAUDE.md 1b)"),
    (re.compile(r"\bTextStyle\("),
     "TextStyle built from scratch -> start from context.type.<style> and "
     ".copyWith(color: ...) (CLAUDE.md 1b)"),
    (re.compile(r"\b\w*ThemeData\("),
     "component theme declared outside lib/core/design/theme/ -> move it into "
     "AppTheme so every instance inherits it (CLAUDE.md 1b)"),

    # --- rule 1c: responsive layout ----------------------------------------
    (re.compile(r"\bMediaQuery\.of\(\s*context\s*\)\.size"),
     "MediaQuery.of(context).size -> use MediaQuery.sizeOf(context), or "
     "LayoutBuilder to lay out from real constraints (CLAUDE.md 1c)"),
    (re.compile(r"\.(width|height)\s*[<>]=?\s*\d"),
     "hardcoded size breakpoint -> respond to constraints with LayoutBuilder / "
     "Flexible instead of branching on device size (CLAUDE.md 1c)"),
]

# Lines that look like violations but are not.
ALLOW = re.compile(
    r"""
      ^\s*(//|///|\*|/\*)      # comments and doc comments
    | \bEdgeInsets\.zero\b
    | \bBorderRadius\.zero\b
    | \bDuration\.zero\b
    | \bColors\.transparent\b  # genuinely semantic; no token needed
    | //\s*(style|token)-ok    # explicit, reviewed exception -- see MARKER
    """,
    re.VERBOSE,
)

# A deliberate, reviewed exception. Rule 1b permits inline styling for
# genuinely one-of-a-kind cases as long as they are marked, so that the next
# reader can tell a decision from an oversight.
MARKER = re.compile(r"//\s*(style|token)-ok")

# How far a standalone marker reaches before we stop trusting it. Long
# enough for a real widget expression, short enough that a stray marker
# cannot exempt an entire file.
MAX_EXEMPT_LINES = 15

GUARDED_PREFIXES = ("lib/features/", "lib/shared/")
EXEMPT_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart", ".mocks.dart")


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    path = payload.get("tool_input", {}).get("file_path", "")
    if not path or not path.endswith(".dart"):
        return 0
    if path.endswith(EXEMPT_SUFFIXES):
        return 0

    project = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    try:
        rel = os.path.relpath(path, project).replace(os.sep, "/")
    except ValueError:
        return 0

    if not rel.startswith(GUARDED_PREFIXES):
        return 0

    try:
        with open(path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except OSError:
        return 0

    # A file that does not import Flutter cannot build a widget, cannot reach a
    # BuildContext, and therefore cannot read `context.*` tokens at all. Domain
    # models, repositories and pure controllers live here. Their literals are
    # data (a fake latency, a retry window, a page size), not design values, so
    # guarding them produces only false positives.
    source = "".join(lines)
    if "import 'package:flutter/" not in source and \
            'import "package:flutter/' not in source:
        return 0

    findings = []
    # A standalone `// style-ok:` comment covers the block it introduces, up to
    # the next blank line. That is what makes the exception usable: in a
    # multi-line widget the offending line is buried inside the expression, so
    # there is nowhere sensible to hang a trailing comment. A trailing marker
    # on a line of code covers only that line.
    block_exempt = False
    exempt_run = 0
    for index, line in enumerate(lines):
        num = index + 1
        stripped = line.strip()

        if not stripped:
            block_exempt = False
            exempt_run = 0
            continue

        if MARKER.search(line):
            # Standalone comment -> exempt the block that follows.
            # Trailing marker on code -> exempt this line only.
            if stripped.startswith("//"):
                block_exempt = True
                exempt_run = 0
            continue

        if block_exempt:
            exempt_run += 1
            if exempt_run <= MAX_EXEMPT_LINES:
                continue
            # A marker must not silently blanket a whole file.
            block_exempt = False

        if ALLOW.search(line):
            continue

        for pattern, explanation in RULES:
            if pattern.search(line):
                findings.append((num, explanation, stripped[:90]))
                break

    if not findings:
        return 0

    out = [
        f"Design-system violations in {rel} "
        f"({len(findings)} found). Files under lib/features/** and "
        "lib/shared/** must read semantic tokens via context.* rather than "
        "literals (rule 1), and must take styling from AppTheme rather than "
        "restating it at the call site (rule 1b).",
        "",
    ]
    for num, explanation, snippet in findings[:15]:
        out.append(f"  {rel}:{num}  {explanation}")
        out.append(f"      {snippet}")
    if len(findings) > 15:
        out.append(f"  ... and {len(findings) - 15} more")
    out += [
        "",
        "Fix by using the token, or by moving the styling into AppTheme. If no "
        "suitable token exists, add one to lib/core/design/ first (see the "
        "/design-token skill) -- do not inline the value.",
        "",
        "If this genuinely IS a one-of-a-kind case -- a one-off hero or empty "
        "state, a deliberate break for emphasis, a third-party widget that "
        "cannot read AppTheme, or a runtime-computed value -- that is allowed. "
        "Mark it `// style-ok: <short reason>` on the line or the line above. "
        "Do not mark something that appears twice: a repeated exception is not "
        "an exception, and belongs in AppTheme or a widget variant.",
    ]
    print("\n".join(out), file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
