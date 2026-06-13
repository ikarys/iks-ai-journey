#!/usr/bin/env bash
#
# UserPromptSubmit hook — detect missing or incomplete pre-commit config.
#
# Contract:
#   * Runs before every user prompt is processed by Claude.
#   * If .pre-commit-config.yaml is absent or missing gitleaks, AND the
#     one-time sentinel for this repo has not been created yet, outputs a
#     system note so Claude can suggest /precommit-setup.
#   * Creates a sentinel file in ~/.claude/precommit-checks/ so the
#     suggestion is emitted exactly once per repo, forever.
#   * Always exits 0 — never blocks the user's prompt.

set -u

# Only meaningful inside a git work tree.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"

# Sentinel keyed on the repo path (md5 keeps the filename short and safe).
SENTINEL_DIR="$HOME/.claude/precommit-checks"
SENTINEL_FILE="$SENTINEL_DIR/$(printf '%s' "$REPO_ROOT" | md5sum | cut -d' ' -f1)"

# Already proposed for this repo — stay silent.
if [ -f "$SENTINEL_FILE" ]; then
  exit 0
fi

CONFIG="$REPO_ROOT/.pre-commit-config.yaml"

needs_setup=0

if [ ! -f "$CONFIG" ]; then
  needs_setup=1
elif ! grep -q "gitleaks" "$CONFIG"; then
  # Config exists but gitleaks is absent — treat as incomplete.
  needs_setup=1
fi

if [ "$needs_setup" = "1" ]; then
  mkdir -p "$SENTINEL_DIR"
  touch "$SENTINEL_FILE"
  echo "[precommit-check] No complete .pre-commit-config.yaml detected in repo: $REPO_ROOT"
  echo "[precommit-check] Missing at minimum: gitleaks secret scanner."
  echo "[precommit-check] Suggest running /precommit-setup once to scaffold a complete config."
  echo "[precommit-check] Do not repeat this suggestion in future turns."
fi

exit 0
