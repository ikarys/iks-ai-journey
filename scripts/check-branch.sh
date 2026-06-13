#!/usr/bin/env bash
#
# PreToolUse hook — refuse edits while on a protected branch (main/master).
#
# Contract:
#   * Runs before Edit/Write/NotebookEdit tool calls.
#   * If the current git branch is main or master, block the edit (exit 2): the
#     message on stderr is fed back to Claude so it can branch first.
#   * Escape hatch: set ALLOW_MAIN_EDITS=1 to permit edits on the protected branch.
#   * Not a git repo, or detached/other branch → allow (exit 0).
#
# Tool-neutral note: this is a Claude Code enforcement mechanism, not portable
# guidance. Other tools would need their own equivalent.

set -u

# Explicit opt-out.
if [ "${ALLOW_MAIN_EDITS:-0}" = "1" ]; then
  exit 0
fi

# Only meaningful inside a work tree.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"

case "$branch" in
  main|master)
    echo "Blocked: editing files directly on '$branch' is not allowed." >&2
    echo "Create a feature branch first (e.g. 'git switch -c feat/my-change')," >&2
    echo "or set ALLOW_MAIN_EDITS=1 to override for this session." >&2
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
