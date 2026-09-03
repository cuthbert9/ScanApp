#!/usr/bin/env python3
"""UserPromptSubmit hook -- plan before execution, and stay device-aware.

Two jobs, both fired when a prompt looks like implementation work:

1. Re-state the plan-before-execution rule when the session is not in plan mode.
2. Re-state the MC9450 constraints, in every mode. This app is built for one
   rugged handheld, and the constraints that follow from that (a 320x533 dp
   canvas, gloves, a hardware trigger, a physical keypad) are invisible in the
   code -- they are the first thing to slip in a long session.

`permissions.defaultMode: "plan"` in settings.json already blocks edits until a
plan is approved, so this hook is a *backstop*, not the primary mechanism. It
matters in exactly one case: the session has left plan mode (Shift+Tab, an
approved plan that rolled into auto mode, or a `--permission-mode` override) and
the next request is a fresh piece of work that deserves its own plan.

It never blocks. It injects a short reminder as additional context, and only
when the prompt actually looks like implementation work -- a question or a
read-only request passes through untouched.
"""
import json
import re
import sys

# Verbs that signal "change the codebase".
BUILD_INTENT = re.compile(
    r"""\b(
        add|create|build|implement|write|make|set\s?up|scaffold|generate
      | fix|repair|resolve|patch|debug
      | refactor|restructure|reorganise|reorganize|rename|move|extract
      | update|change|modify|edit|adjust|tweak|replace|swap
      | remove|delete|drop|strip|clean\s?up
      | migrate|port|upgrade|bump|install|wire|integrate|connect
      | style|theme|redesign|revamp
    )\b""",
    re.IGNORECASE | re.VERBOSE,
)

# Prompts that are clearly not asking for code changes.
# Deliberately excludes bare modals (can/could/would/will/should). "Can you
# set up go_router" is a work request, not a question -- and BUILD_INTENT
# already gates this check, so dropping them costs nothing: a modal-opening
# prompt with no build verb never reaches here anyway.
READ_ONLY_INTENT = re.compile(
    r"""^\s*(
        what|why|who|when|where|which
      | how\s+(does|do|did|is|are|should|would|can)
      | explain|describe|summarise|summarize|show|list|find|search|look|read
      | tell\s+me|walk\s+me|help\s+me\s+understand
      | review|check|compare|analyse|analyze|audit|inspect
    )\b""",
    re.IGNORECASE | re.VERBOSE,
)

PLAN_REMINDER = (
    "PLAN FIRST (.claude/settings.json + CLAUDE.md): this session is not in "
    "plan mode, but the plan-before-execution rule still applies.\n\n"
    "Before editing any file, present an implementation plan and wait for "
    "explicit approval. The plan must state: (1) what changes and why, "
    "(2) the exact files to create or modify, (3) the approach and any "
    "trade-off worth a decision, (4) what is deliberately out of scope, "
    "(5) how the result will be verified, (6) device impact, and "
    "(7) assumptions and open questions.\n\n"
    "If the request is genuinely trivial -- a typo, a one-line tweak, a "
    "question -- say so in one line and proceed; do not pad it into a "
    "ceremonial plan."
)

DEVICE_REMINDER = (
    "TARGET DEVICE: Zebra MC9450 rugged handheld. Hold these in mind while "
    "implementing, not just while planning:\n"
    "  - Canvas is ~320x533 dp (800x480 @1.5). Rotated it is 533x320 -- only "
    "320 dp of height -- and the keyboard leaves ~280 dp. Make it scroll.\n"
    "  - Operated with gloves: 56 dp targets for anything tapped in a hurry, "
    "48 dp floor.\n"
    "  - Scanning is DataWedge intent broadcasts from the hardware imager, not "
    "a camera preview. Scanning must never require an on-screen tap.\n"
    "  - There is a physical keypad: every action key-reachable, focus "
    "obviously visible.\n"
    "  - Used in bright sun and dim aisles: high-contrast semantic colours, "
    "check both themes.\n"
    "  - Hundreds of scans per shift: no animation or dialog may gate the next "
    "scan, and nothing may accumulate per scan without being bounded.\n"
    "  - Warehouse Wi-Fi has dead zones: a failed call must leave the operator "
    "able to keep working."
)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    prompt = (payload.get("user_input") or "").strip()
    if not prompt:
        return 0

    # A slash command carries its own instructions.
    if prompt.startswith("/"):
        return 0

    # Very short prompts are usually acknowledgements ("yes", "go ahead", "ok").
    # An approval to proceed must not re-trigger the reminder.
    if len(prompt) < 12:
        return 0

    if READ_ONLY_INTENT.match(prompt):
        return 0

    if not BUILD_INTENT.search(prompt):
        return 0

    # The device constraints apply in every mode. The plan reminder is only
    # needed when the harness is not already enforcing it via plan mode.
    parts = [DEVICE_REMINDER]
    if payload.get("permission_mode") != "plan":
        parts.insert(0, PLAN_REMINDER)

    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": "\n\n".join(parts),
                }
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
