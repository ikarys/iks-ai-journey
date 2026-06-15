#!/usr/bin/env bash
#
# UserPromptSubmit hook — detect missing or incomplete pre-commit config.
#
# Contract:
#   * Runs before every user prompt is processed by Claude.
#   * Stays completely silent once the repo has a complete config
#     (a real `- id: gitleaks` hook entry) — no sentinel, nothing to do.
#   * While the config is missing/incomplete, emits a system note so Claude
#     can suggest /precommit-setup, but at most once per session (a session
#     sentinel throttles it). The nudge therefore comes back in a new
#     session if the repo is still unprotected, instead of being silenced
#     forever after the first mention.
#   * Always exits 0 — never blocks the user's prompt.

set -u

# Portable string hash: GNU md5sum, BSD/macOS md5, then cksum as last resort.
hash_str() {
  if command -v md5sum >/dev/null 2>&1; then
    printf '%s' "$1" | md5sum | cut -d' ' -f1
  elif command -v md5 >/dev/null 2>&1; then
    printf '%s' "$1" | md5 -q
  else
    printf '%s' "$1" | cksum | cut -d' ' -f1
  fi
}

# Resolve a session id to throttle the nudge per session. Harness-neutral order:
#   1. $PRECOMMIT_SESSION_ID  (pi / cursor adapters set this)
#   2. first CLI arg          (generic caller)
#   3. session_id in a JSON payload on stdin (Claude Code's hook contract)
#   4. per-day key            (last resort when nothing identifies the session)
SESSION_ID="${PRECOMMIT_SESSION_ID:-${1:-}}"
if [ -z "$SESSION_ID" ]; then
  INPUT="$(cat 2>/dev/null || true)"
  SESSION_ID="$(printf '%s' "$INPUT" \
    | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]+"' \
    | head -n1 | grep -oE '"[^"]+"$' | tr -d '"')"
fi
[ -n "$SESSION_ID" ] || SESSION_ID="day-$(date +%Y%m%d)"

# Only meaningful inside a git work tree.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
CONFIG="$REPO_ROOT/.pre-commit-config.yaml"

# Config is complete when an actual gitleaks hook entry is present (a bare
# mention in a comment or the repo URL does not count). Nothing to nag about.
if [ -f "$CONFIG" ] && grep -qE '^[[:space:]]*-[[:space:]]*id:[[:space:]]*gitleaks([[:space:]]|$)' "$CONFIG"; then
  exit 0
fi

# Incomplete/missing — throttle the nudge to once per session for this repo.
SENTINEL_DIR="$HOME/.claude/precommit-checks"
SENTINEL_FILE="$SENTINEL_DIR/$(hash_str "$REPO_ROOT:$SESSION_ID")"

# Already nagged in this session — stay silent.
if [ -f "$SENTINEL_FILE" ]; then
  exit 0
fi

mkdir -p "$SENTINEL_DIR"
touch "$SENTINEL_FILE"
echo "[precommit-check] No complete .pre-commit-config.yaml detected in repo: $REPO_ROOT"
echo "[precommit-check] Missing at minimum: a gitleaks secret-scanner hook."
echo "[precommit-check] Suggest running /precommit-setup once to scaffold a complete config."
echo "[precommit-check] Do not repeat this suggestion in future turns."

exit 0
