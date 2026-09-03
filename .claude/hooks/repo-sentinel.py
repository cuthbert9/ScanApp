#!/usr/bin/env python3
"""Stop hook — the two things that rot silently as a project grows.

1. .gitignore drift: a new tool starts emitting artifacts, nobody adds them,
   and they get committed. Once a generated file is tracked it produces merge
   conflicts forever, so this is worth catching on the very first occurrence.

2. Documentation drift: code structure changes, ARCHITECTURE.md does not, and
   six months later the doc actively misleads whoever reads it.

Both checks only fire on a *real* signal, and both are suppressed when the stop
hook is already active so a session can never loop on them.
"""
import json
import os
import subprocess
import sys

# Filenames/extensions that are build output or credentials -- never committed.
ARTIFACT_SUFFIXES = (
    ".g.dart", ".freezed.dart", ".gr.dart", ".mocks.dart", ".config.dart",
    ".apk", ".aab", ".ipa", ".jks", ".keystore", ".p12", ".p8", ".pem",
    ".class", ".dex", ".log", ".lcov",
)
ARTIFACT_NAMES = (
    ".env", ".DS_Store", "key.properties", "lcov.info",
    "google-services.json", "GoogleService-Info.plist",
    "firebase_options.dart", "local.properties",
)
ARTIFACT_DIRS = (
    "build/", ".dart_tool/", "coverage/", ".gradle/", "Pods/",
    "DerivedData/", ".kotlin/",
)

# A change to any of these means the architecture doc may now be stale.
STRUCTURAL = ("lib/", "pubspec.yaml", "analysis_options.yaml")
DOC_FILE = "ARCHITECTURE.md"


def git(*args: str) -> str:
    try:
        return subprocess.run(
            ("git",) + args,
            capture_output=True, text=True, timeout=10,
        ).stdout
    except Exception:
        return ""


def is_artifact(path: str) -> bool:
    name = os.path.basename(path)
    if name.startswith(".env") and not name.endswith(".example"):
        return True
    if name in ARTIFACT_NAMES:
        return True
    if path.endswith(ARTIFACT_SUFFIXES):
        return True
    return any(seg in path for seg in ARTIFACT_DIRS)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        payload = {}

    # Never re-fire while we are already asking Claude to continue.
    if payload.get("stop_hook_active"):
        return 0

    project = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    os.chdir(project)

    if not os.path.isdir(os.path.join(project, ".git")):
        return 0

    status = git("status", "--porcelain=v1", "-uall")
    if not status.strip():
        return 0

    changed = []
    for line in status.splitlines():
        if len(line) < 4:
            continue
        path = line[3:].strip().strip('"')
        # Renames read as "old -> new"; we care about the destination.
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        changed.append(path)

    messages = []

    # --- 1. artifacts that escaped .gitignore -------------------------------
    leaked = sorted({p for p in changed if is_artifact(p)})
    if leaked:
        messages.append(
            "Build artifacts or credentials are NOT ignored and would be "
            "committed:\n"
            + "\n".join(f"  - {p}" for p in leaked[:20])
            + ("\n  ..." if len(leaked) > 20 else "")
            + "\n\nAdd matching patterns to .gitignore now (CLAUDE.md, "
              "'definition of done'). If any of these were already committed, "
              "also run `git rm --cached <path>`."
        )

    # --- 2. architecture doc drift -------------------------------------------
    structural = [
        p for p in changed
        if p.startswith(STRUCTURAL) and not is_artifact(p)
    ]
    doc_touched = any(os.path.basename(p) == DOC_FILE for p in changed)
    doc_exists = os.path.isfile(os.path.join(project, DOC_FILE))

    # Before the first commit every file is untracked, so "what changed" tells
    # us nothing about drift. Artifact leakage above still matters -- an
    # initial commit is exactly when a keystore gets committed by accident --
    # but documentation drift does not exist yet.
    has_commits = bool(git("rev-parse", "--verify", "HEAD").strip())

    # Only nag for genuinely structural work, not a one-line tweak.
    if has_commits and structural and not doc_touched and len(structural) >= 3:
        if doc_exists:
            messages.append(
                f"{len(structural)} structural files changed but {DOC_FILE} "
                "was not updated:\n"
                + "\n".join(f"  - {p}" for p in structural[:10])
                + ("\n  ..." if len(structural) > 10 else "")
                + f"\n\nRun the /docs-sync skill to bring {DOC_FILE} back in "
                  "line, then stop."
            )
        else:
            messages.append(
                f"{DOC_FILE} does not exist yet, and the project now has real "
                "structure. Run the /docs-sync skill to create it so the next "
                "developer (or session) can orient without reading every file."
            )

    if not messages:
        return 0

    print("\n\n".join(messages), file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
