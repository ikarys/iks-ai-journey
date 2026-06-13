#!/usr/bin/env bash
#
# PostToolUse hook — auto-format / lint a file after Claude Code edits it.
#
# Contract:
#   * Receives the hook payload as JSON on stdin (Claude Code PostToolUse).
#   * Dispatches a formatter/linter by file extension.
#   * Every tool is guarded by `command -v` — a missing tool is silently skipped.
#   * This hook NEVER fails the edit: it always exits 0. Formatting is best-effort.
#
# Tool-neutral note: this enforcement layer is Claude Code-specific. The *guidance*
# in canonical/rules/ deliberately does not duplicate what these tools check.

set -u

# --- Resolve the edited file path from the hook payload -----------------------
payload="$(cat 2>/dev/null || true)"

file=""
if command -v jq >/dev/null 2>&1; then
  file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
fi
# Fallback if jq is absent: best-effort grep for "file_path": "...".
if [ -z "$file" ]; then
  file="$(printf '%s' "$payload" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -n1 | sed -E 's/.*:[[:space:]]*"([^"]+)"/\1/')"
fi

# Nothing to do without a real, existing file.
[ -n "$file" ] && [ -f "$file" ] || exit 0

# Run a command only if it exists; swallow its output so we never disturb the edit.
run() { command -v "$1" >/dev/null 2>&1 && "$@" >/dev/null 2>&1 || true; }

case "$file" in
  *.tf|*.hcl)
    run terraform fmt "$file"
    run tflint --filter="$file"
    ;;
  *.py)
    run ruff format "$file"
    run ruff check --fix "$file"
    ;;
  *.rs)
    run rustfmt "$file"
    ;;
  Dockerfile|*Dockerfile|Dockerfile.*)
    run hadolint "$file"
    ;;
  *k8s*/*.yaml|*manifests*/*.yaml)
    run kubeconform -summary "$file"
    ;;
  *.sh)
    run shfmt -w "$file"
    run shellcheck "$file"
    ;;
  *.json)
    run jq . "$file"
    ;;
esac

exit 0
