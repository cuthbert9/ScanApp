#!/usr/bin/env bash
# PostToolUse(Edit|Write) — format the edited Dart file and surface analyzer
# errors immediately, while the change is still in working memory.
#
# Exit 2 hands stderr back to Claude so it can fix the problem in the same turn
# rather than discovering it at the end of a long task.
set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR" || exit 0

FILE_PATH="$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(d.get("tool_input", {}).get("file_path", ""))
' 2>/dev/null)"

[ -z "$FILE_PATH" ] && exit 0
[ -f "$FILE_PATH" ] || exit 0
case "$FILE_PATH" in
  *.dart) ;;
  *) exit 0 ;;
esac
# Generated code is not ours to format or lint.
case "$FILE_PATH" in
  *.g.dart|*.freezed.dart|*.gr.dart|*.mocks.dart) exit 0 ;;
esac

command -v dart >/dev/null 2>&1 || exit 0

dart format "$FILE_PATH" >/dev/null 2>&1

ANALYSIS="$(dart analyze --fatal-infos "$FILE_PATH" 2>&1)"
STATUS=$?

if [ $STATUS -ne 0 ]; then
  {
    echo "Analyzer issues in $FILE_PATH — fix before moving on:"
    echo
    echo "$ANALYSIS" | grep -E '^\s+(error|warning|info)' | head -25
  } >&2
  exit 2
fi

exit 0
