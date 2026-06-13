#!/usr/bin/env bash
#
# bootstrap.sh — make the repo usable after a fresh clone.
#
# Idempotent. Safe to run repeatedly. It:
#   1. (Re)creates the relative symlinks that adapt the canonical source of truth
#      into Claude Code's expected layout. Windows clones often do not preserve
#      symlinks, so we always recreate them from scratch.
#   2. Points git at the tracked hooks directory (core.hooksPath=git-hooks).
#   3. Marks scripts and git hooks executable.
#
# Run from anywhere: it resolves its own location.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

echo "▶ Bootstrapping $repo_root"

# --- 1. Relative symlinks: canonical (source of truth) -> .claude (adapter) ----
# link <link-path> <target-relative-to-link-dir>
link() {
  local link_path="$1" target="$2"
  local link_dir
  link_dir="$(dirname "$link_path")"
  mkdir -p "$link_dir"

  # Remove whatever is there (stale link, leftover file/dir) so this is idempotent.
  if [ -L "$link_path" ] || [ -e "$link_path" ]; then
    rm -rf "$link_path"
  fi

  ln -s "$target" "$link_path"
  echo "  ✓ symlink $link_path -> $target"
}

link ".claude/CLAUDE.md" "../AGENTS.md"
link ".claude/rules"     "../canonical/rules"
link ".claude/skills"    "../canonical/skills"

# --- 2. Git hooks -------------------------------------------------------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git config core.hooksPath git-hooks
  echo "  ✓ git core.hooksPath = git-hooks"
else
  echo "  ⚠ not a git repository — skipped core.hooksPath"
fi

# --- 3. Executable bits -------------------------------------------------------
chmod +x scripts/*.sh bootstrap.sh 2>/dev/null || true
chmod +x git-hooks/* 2>/dev/null || true
echo "  ✓ scripts and git hooks marked executable"

echo "✓ Bootstrap complete."
