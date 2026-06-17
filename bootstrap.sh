#!/usr/bin/env bash
#
# bootstrap.sh — make the repo usable after a fresh clone, per AI agent.
#
# Idempotent. Safe to run repeatedly.
#
# The canonical source of truth is AGENTS.md + canonical/. Each supported agent
# gets a thin adapter so it reads that source the way *it* expects. AGENTS.md is
# already the cross-agent standard (read natively by pi.dev, opencode, Cursor),
# so guidance needs little or nothing. Skills differ: Claude Code reads them via
# repo-scoped .claude/ symlinks; pi.dev via a user-global settings `skills` entry.
#
# Usage:
#   ./bootstrap.sh                 # interactive checkbox select (or all, if no TTY)
#   ./bootstrap.sh claude pi       # non-interactive: configure these agents
#   ./bootstrap.sh --all           # non-interactive: configure every known agent
#
# Conventional Commits and secret scanning are enforced via .pre-commit-config.yaml.
#
# Pretty output uses plain ANSI + Unicode — no external deps (no gum). Colour is
# auto-disabled when stdout is not a TTY or NO_COLOR is set. The interactive
# checkbox selector falls back to line input when there is no /dev/tty.
#
# Run from anywhere: it resolves its own location.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

# --- Colours / UI (TTY + NO_COLOR aware) -------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$'\e[1m'; DIM=$'\e[2m'; RESET=$'\e[0m'
  CYAN=$'\e[36m'; MAGENTA=$'\e[35m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'
else
  BOLD=''; DIM=''; RESET=''; CYAN=''; MAGENTA=''; GREEN=''; YELLOW=''
fi

# Centre $1 inside width $2 (ASCII-only text → ${#…} is a true column count).
center() {
  local s="$1" w="$2" len=${#1} pad lpad rpad
  pad=$(( w - len )); (( pad < 0 )) && pad=0
  lpad=$(( pad / 2 )); rpad=$(( pad - lpad ))
  printf '%*s%s%*s' "$lpad" '' "$s" "$rpad" ''
}

# ASCII-art banner — "IKS AI" in the ANSI Shadow figlet style (frozen here so
# there is no runtime figlet dependency). Width ≈ 35 columns.
banner() {
  local w=35 tag="J O U R N E Y" sub="source: AGENTS.md + canonical/"
  printf '%s\n' \
    "" \
    "${BOLD}${MAGENTA}██╗ ██╗  ██╗ ███████╗   █████╗  ██╗${RESET}" \
    "${BOLD}${MAGENTA}██║ ██║ ██╔╝ ██╔════╝  ██╔══██╗ ██║${RESET}" \
    "${BOLD}${MAGENTA}██║ █████╔╝  ███████╗  ███████║ ██║${RESET}" \
    "${BOLD}${MAGENTA}██║ ██╔═██╗  ╚════██║  ██╔══██║ ██║${RESET}" \
    "${BOLD}${MAGENTA}██║ ██║  ██╗ ███████║  ██║  ██║ ██║${RESET}" \
    "${BOLD}${MAGENTA}╚═╝ ╚═╝  ╚═╝ ╚══════╝  ╚═╝  ╚═╝ ╚═╝${RESET}"
  printf '%s\n' "${BOLD}${MAGENTA}$(center "$tag" "$w")${RESET}"
  printf '%s\n' "${DIM}$(center "$sub" "$w")${RESET}"
}

# Status helpers. step/ok/info → stdout; warn/err → stderr.
step() { printf '%s\n' "${CYAN}▶${RESET} ${BOLD}$*${RESET}"; }
ok()   { printf '%s\n' "  ${GREEN}✓${RESET} $*"; }
info() { printf '%s\n' "  ${DIM}ℹ $*${RESET}"; }
warn() { printf '%s\n' "  ${YELLOW}⚠${RESET} $*" >&2; }
err()  { printf '%s\n' "${YELLOW}✖${RESET} $*" >&2; }

# --- Interactive checkbox multi-select (pure bash, no deps) -------------------
# Inputs (globals):  _MS_KEYS[] _MS_LABELS[] (index-aligned), _MS_PROMPT,
#                    _MS_DEFAULT (1 = all pre-checked, 0 = none).
# Output:            chosen keys on stdout, one per line.
# The menu is drawn on stderr and keystrokes are read from /dev/tty, so stdout
# stays clean for capture even inside $(...) / process substitution.
interactive_select() {
  local n=${#_MS_KEYS[@]} cursor=0 i key rest
  local -a checked=()
  for ((i = 0; i < n; i++)); do checked[i]=${_MS_DEFAULT:-1}; done

  _ms_row() {  # draw one row, clearing to end-of-line
    local idx=$1 ptr box
    [ "$idx" -eq "$cursor" ] && ptr="${CYAN}❯${RESET}" || ptr=' '
    [ "${checked[idx]}" -eq 1 ] && box="${GREEN}◉${RESET}" || box="${DIM}○${RESET}"
    printf '%s %s %s%s%s  %s%s%s\e[K\n' "$ptr" "$box" \
      "$BOLD" "${_MS_KEYS[idx]}" "$RESET" "$DIM" "${_MS_LABELS[idx]}" "$RESET" >&2
  }

  printf '%s %s\n' \
    "${BOLD}${_MS_PROMPT}${RESET}" \
    "${DIM}(↑↓ move · space toggle · a all · enter confirm)${RESET}" >&2

  printf '\e[?25l' >&2                          # hide cursor while navigating
  trap 'printf "\e[?25h" >&2' RETURN
  trap 'printf "\e[?25h" >&2; exit 130' INT

  for ((i = 0; i < n; i++)); do _ms_row "$i"; done

  while true; do
    IFS= read -rsn1 key </dev/tty || break
    case "$key" in
      '')  break ;;                            # Enter confirms
      ' ') checked[cursor]=$(( 1 - checked[cursor] )) ;;
      a|A)                                     # toggle all on/off
        local allon=1
        for ((i = 0; i < n; i++)); do [ "${checked[i]}" -eq 0 ] && allon=0 || true; done
        for ((i = 0; i < n; i++)); do checked[i]=$(( 1 - allon )); done ;;
      k) ((cursor > 0))     && ((cursor--)) || true ;;   # vim up
      j) ((cursor < n - 1)) && ((cursor++)) || true ;;   # vim down
      $'\e')                                   # arrow keys: ESC [ A/B
        read -rsn2 -t 0.05 rest </dev/tty || true
        case "$rest" in
          '[A') ((cursor > 0))     && ((cursor--)) || true ;;
          '[B') ((cursor < n - 1)) && ((cursor++)) || true ;;
        esac ;;
    esac
    printf '\e[%dA' "$n" >&2                    # rewind n rows, redraw
    for ((i = 0; i < n; i++)); do _ms_row "$i"; done
  done

  for ((i = 0; i < n; i++)); do
    [ "${checked[i]}" -eq 1 ] && printf '%s\n' "${_MS_KEYS[i]}"
  done
  # Never let a final "nothing checked" test leak exit 1 — under set -e that
  # would abort the caller's  var="$(interactive_select)"  assignment.
  return 0
}

# --- Agent registry ----------------------------------------------------------
# Keep KEYS and LABELS index-aligned. To add an agent later (e.g. cursor,
# opencode): add a key + label here and a matching setup_<key> function.
KEYS=(claude pi vscode)
LABELS=(
  "Claude Code — .claude/ symlinks, settings.json"
  "pi.dev      — reads AGENTS.md natively; registers canonical/skills in settings"
  "VSCode (Win)— copy Claude config into the Windows .claude home (WSL hosts)"
)

# --- Optional plugin registry ------------------------------------------------
# Cross-agent tooling, installed globally on your machine (NOT repo-scoped).
# Opt-in only: never installed from args or in CI (no TTY) — it runs a remote
# installer, so it must be a deliberate interactive choice. Keep PLUGIN_KEYS /
# PLUGIN_LABELS index-aligned; install command goes in PLUGIN_CMD_<key>.
PLUGIN_KEYS=(caveman)
PLUGIN_LABELS=(
  "caveman — ultra-terse multi-agent comms (runs remote curl|bash installer)"
)
PLUGIN_CMD_caveman='curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash'

# --- Helpers -----------------------------------------------------------------

# link <link-path> <target-relative-to-link-dir>
# Removes whatever is there first so this survives re-runs and Windows clones
# (which often materialise symlinks as plain files).
link() {
  local link_path="$1" target="$2"
  mkdir -p "$(dirname "$link_path")"
  if [ -L "$link_path" ] || [ -e "$link_path" ]; then
    rm -rf "$link_path"
  fi
  ln -s "$target" "$link_path"
  ok "symlink ${BOLD}$link_path${RESET} ${DIM}->${RESET} $target"
}

# --- Per-agent setup ---------------------------------------------------------

# The repo's security deny rules. Keep in sync with permissions.deny in
# .claude/settings.json: both the secret-reading guards and the
# destructive-command guards from CLAUDE.md §Safety.
CLAUDE_DENY_PATTERNS=(
  # Secret-reading guards
  'Read(.env)'
  'Read(.env.*)'
  'Read(**/.env)'
  'Read(**/.env.*)'
  'Read(**/*.pem)'
  'Read(**/*.key)'
  'Read(**/*.crt)'
  'Read(**/secrets/**)'
  'Read(**/*secret*)'
  'Read(**/*secrets*)'
  'Read(**/*credentials*)'
  # Destructive-command guards (CLAUDE.md §Safety)
  'Bash(rm -rf:*)'
  'Bash(rm -fr:*)'
  'Bash(sudo rm:*)'
  'Bash(terraform apply:*)'
  'Bash(terraform destroy:*)'
  'Bash(kubectl delete:*)'
)

# Idempotent merge of the repo's security deny rules into a settings.json file.
# The repo's .claude/settings.json already enforces these within this project;
# merging into a user-global settings.json extends the same protection to every
# Claude Code session that reads that home. Used for both the WSL home
# (~/.claude) and, via setup_vscode, the Windows home that the VSCode extension
# reads. It only restricts, never grants.
_claude_merge_deny() {
  local file="$1"
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found — skipping deny rules in $file"
    info "add manually under permissions.deny: ${CLAUDE_DENY_PATTERNS[*]}"
    return 0
  fi

  mkdir -p "$(dirname "$file")"
  [ -f "$file" ] || printf '{}\n' > "$file"

  local jq_patterns tmp
  jq_patterns="$(printf '%s\n' "${CLAUDE_DENY_PATTERNS[@]}" | jq -R . | jq -s .)"
  tmp="$(mktemp)"
  if jq --argjson new_denies "$jq_patterns" \
       '.permissions.deny = ((.permissions.deny // []) + $new_denies | unique)' \
       "$file" > "$tmp"; then
    mv "$tmp" "$file"
    ok "deny rules merged → ${BOLD}$file${RESET}"
  else
    rm -f "$tmp"
    warn "could not update $file — left untouched"
  fi
}

setup_claude() {
  step "Claude Code"
  link ".claude/CLAUDE.md" "../AGENTS.md"
  link ".claude/rules"     "../canonical/rules"
  link ".claude/skills"    "../canonical/skills"
  link ".claude/commands"  "../canonical/commands"
  # .claude/settings.json (permissions + hooks) is tracked, not generated.
  ok "settings.json + hooks already tracked in .claude/"
  # The enforcement hooks (check-branch, check-precommit) bind to
  # $CLAUDE_PROJECT_DIR and only make sense inside this repo, so they stay
  # project-scoped by design — they are not propagated to other sessions.
  info "enforcement hooks stay project-scoped (bound to \$CLAUDE_PROJECT_DIR)"
}

# pi_register_array <settings-file> <field> <dir>
# Idempotent unique-append of an absolute path into a pi settings.json array
# field (.skills / .prompts): drop any existing copy of the path, re-add once.
# Replaces the file only on a successful jq run.
pi_register_array() {
  local file="$1" field="$2" dir="$3" tmp
  tmp="$(mktemp)"
  if jq --arg f "$field" --arg dir "$dir" \
       '.[$f] = ((.[$f] // []) - [$dir] + [$dir])' \
       "$file" > "$tmp"; then
    mv "$tmp" "$file"
    ok "registered ${BOLD}$dir${RESET} in pi ${field}[]"
  else
    rm -f "$tmp"
    warn "could not update $file (${field}) — left untouched"
  fi
}

setup_pi() {
  step "pi.dev"
  # pi loads AGENTS.md from the project root and parent dirs natively, plus a
  # global ~/.pi/agent/AGENTS.md. Nothing to generate for guidance.
  ok   "AGENTS.md at repo root is read natively — nothing to generate"
  info "for global rules, drop an AGENTS.md in ~/.pi/agent/ (your machine)"

  # Unlike Claude (repo-scoped .claude/ symlinks), pi discovers skills and
  # prompt-template commands from user-global locations or settings arrays. We
  # register the canonical dirs so pi reads the single source of truth directly
  # — no copies, no drift. Docs: pi.dev/docs/latest/{skills,prompt-templates}.
  local pi_settings="$HOME/.pi/agent/settings.json"

  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found — cannot register skills/prompts in $pi_settings"
    info "add manually:  \"skills\":  [\"$repo_root/canonical/skills\"]"
    info "               \"prompts\": [\"$repo_root/canonical/commands\"]"
    return 0
  fi

  mkdir -p "$(dirname "$pi_settings")"
  [ -f "$pi_settings" ] || printf '{}\n' > "$pi_settings"

  pi_register_array "$pi_settings" skills  "$repo_root/canonical/skills"
  pi_register_array "$pi_settings" prompts "$repo_root/canonical/commands"
  info "user-global — pi reads canonical/ directly (no copies)"
  info ".pi/extensions/enforce.ts is auto-discovered — same scripts/ as Claude"
}

# VSCode Claude Code on a Windows host (WSL setup). The Windows-side extension
# uses the *Windows* home (C:\Users\<you>\.claude), NOT the WSL home — proven by
# the settings.json the extension itself writes there. So the global wiring
# done for the WSL ~/.claude never reaches it. This copies the same user-global
# config into the Windows .claude home: instructions, commands, skills, and the
# security deny rules. Copies, not symlinks — Windows processes don't follow
# WSL symlinks across /mnt/c. Re-run bootstrap after editing canonical/ to
# refresh them. No-op when there is no Windows drive (plain Linux / CI).
setup_vscode() {
  step "VSCode (Windows host) — Claude Code config"

  if [ ! -d /mnt/c/Users ]; then
    info "no /mnt/c/Users — not a WSL host with a Windows drive; skipping"
    return 0
  fi

  # Prefer the Windows user whose VSCode actually has the Claude Code extension;
  # fall back to the first user with a .claude or VSCode User dir.
  local win_home="" d
  for d in /mnt/c/Users/*; do
    [ -d "$d" ] || continue
    case "${d##*/}" in Public|Default|"Default User"|"All Users") continue ;; esac
    if ls "$d"/.vscode/extensions/anthropic.claude-code-* >/dev/null 2>&1; then
      win_home="$d"; break
    fi
  done
  if [ -z "$win_home" ]; then
    for d in /mnt/c/Users/*; do
      { [ -d "$d/.claude" ] || [ -d "$d/AppData/Roaming/Code/User" ]; } \
        && { win_home="$d"; break; }
    done
  fi
  if [ -z "$win_home" ]; then
    warn "could not locate a Windows user home under /mnt/c/Users — skipping"
    return 0
  fi
  info "Windows home: ${BOLD}$win_home${RESET}"

  local claude_dir="$win_home/.claude"
  mkdir -p "$claude_dir"

  # Global instructions (read as ~/.claude/CLAUDE.md), plus user-global commands
  # and skills. Replace dirs wholesale so deletions in canonical/ propagate.
  cp -f "AGENTS.md" "$claude_dir/CLAUDE.md"
  ok "copied ${BOLD}AGENTS.md${RESET} ${DIM}->${RESET} $claude_dir/CLAUDE.md"
  rm -rf "$claude_dir/commands" "$claude_dir/skills"
  cp -rf "canonical/commands" "$claude_dir/commands"
  cp -rf "canonical/skills"   "$claude_dir/skills"
  ok "copied ${BOLD}canonical/{commands,skills}${RESET} ${DIM}->${RESET} $claude_dir/"

  # Same security deny rules the CLI's WSL home gets.
  _claude_merge_deny "$claude_dir/settings.json"

  info "copies, not symlinks — re-run bootstrap after editing canonical/"
  info "project hooks stay in the repo's .claude/ (loaded when you open the repo)"
}

# --- Selection logic ---------------------------------------------------------

# Resolve an agent token (name or 1-based index) to a registry key; "" if unknown.
resolve_token() {
  local tok="$1" i
  for i in "${!KEYS[@]}"; do
    [ "$tok" = "${KEYS[$i]}" ] && { echo "${KEYS[$i]}"; return; }
    [ "$tok" = "$((i + 1))" ]  && { echo "${KEYS[$i]}"; return; }
  done
  echo ""
}

# Prints the chosen keys, one per line, on stdout (kept colour-free so the
# caller can capture it). All UI goes to stderr / the tty.
choose_agents() {
  # 1. Explicit args win (non-interactive).
  if [ "$#" -gt 0 ]; then
    if [ "$1" = "--all" ]; then printf '%s\n' "${KEYS[@]}"; return; fi
    local tok key
    for tok in "$@"; do
      key="$(resolve_token "$tok")"
      if [ -z "$key" ]; then
        err "Unknown agent: '$tok' (known: ${KEYS[*]})"
        exit 1
      fi
      echo "$key"
    done
    return
  fi

  # 2. No args + no TTY (CI) → configure everything.
  if [ ! -t 0 ]; then printf '%s\n' "${KEYS[@]}"; return; fi

  # 3. Interactive checkbox (preferred), with a line-input fallback.
  if [ -r /dev/tty ]; then
    _MS_KEYS=("${KEYS[@]}"); _MS_LABELS=("${LABELS[@]}")
    _MS_PROMPT="Select agents to configure"; _MS_DEFAULT=1
    interactive_select
    return
  fi

  # 3b. Fallback: space-separated line input.
  printf '%s\n' "${BOLD}Which agents do you want to configure?${RESET}" >&2
  local i
  for i in "${!KEYS[@]}"; do
    printf '  %s%d)%s %s%s%s  %s%s%s\n' \
      "$CYAN" "$((i + 1))" "$RESET" \
      "$BOLD" "${KEYS[$i]}" "$RESET" \
      "$DIM" "${LABELS[$i]}" "$RESET" >&2
  done
  printf '%s' "${DIM}numbers/names, \"a\" for all [default: all]:${RESET} " >&2
  local reply
  read -r reply
  case "${reply// /}" in
    ""|a|all) printf '%s\n' "${KEYS[@]}"; return ;;
  esac
  local tok key
  for tok in $reply; do
    key="$(resolve_token "$tok")"
    [ -n "$key" ] && echo "$key" || warn "ignoring unknown agent: '$tok'"
  done
}

# --- Optional plugins (interactive opt-in only) ------------------------------
# Prompts only on a real TTY. Default = none. Runs each chosen plugin's remote
# installer. Skipped entirely with no TTY (CI) so setup never does surprise RCE.
install_plugins() {
  [ -t 0 ] || return 0
  [ "${#PLUGIN_KEYS[@]}" -gt 0 ] || return 0
  echo >&2

  local -a picks=()
  if [ -r /dev/tty ]; then
    _MS_KEYS=("${PLUGIN_KEYS[@]}"); _MS_LABELS=("${PLUGIN_LABELS[@]}")
    _MS_PROMPT="Optional global plugins ${DIM}(installed on your machine)${RESET}"
    _MS_DEFAULT=0
    mapfile -t picks < <(interactive_select)
  else
    step "Optional global plugins ${DIM}(cross-agent, installed on your machine)${RESET}" >&2
    local i
    for i in "${!PLUGIN_KEYS[@]}"; do
      printf '  %s%d)%s %s\n' "$CYAN" "$((i + 1))" "$RESET" "${PLUGIN_LABELS[$i]}" >&2
    done
    printf '%s' "${DIM}numbers/names, \"a\" for all [default: none]:${RESET} " >&2
    local reply tok j
    read -r reply
    case "${reply// /}" in
      a|all) picks=("${PLUGIN_KEYS[@]}") ;;
      "")    : ;;
      *)
        for tok in $reply; do
          for j in "${!PLUGIN_KEYS[@]}"; do
            { [ "$tok" = "${PLUGIN_KEYS[$j]}" ] || [ "$tok" = "$((j + 1))" ]; } \
              && { picks+=("${PLUGIN_KEYS[$j]}"); break; }
          done
        done ;;
    esac
  fi

  if [ "${#picks[@]}" -eq 0 ]; then
    info "no plugins installed" >&2
    return 0
  fi

  local key cmd
  for key in "${picks[@]}"; do
    cmd="PLUGIN_CMD_${key}"
    step "installing plugin: $key" >&2
    printf '%s\n' "  ${DIM}\$ ${!cmd}${RESET}" >&2
    if eval "${!cmd}"; then
      ok "$key installed" >&2
    else
      err "$key install failed (continuing)"
    fi
  done
}

# --- Main --------------------------------------------------------------------

banner
echo

# Command substitution (not process substitution) so a hard failure inside
# choose_agents — e.g. an unknown agent passed as an arg — propagates here and
# aborts the script. stdin/stderr stay attached for the interactive prompt.
chosen_raw="$(choose_agents "$@")"
chosen=()
[ -n "$chosen_raw" ] && mapfile -t chosen <<< "$chosen_raw"
if [ "${#chosen[@]}" -eq 0 ]; then
  warn "No agent selected — only wiring tool-neutral git hooks."
fi

echo
# De-duplicate while preserving order, then run each agent's setup.
# ${arr[@]+"${arr[@]}"} expands to nothing (not an unbound-var error) when empty.
declare -A seen=()
for key in ${chosen[@]+"${chosen[@]}"}; do
  [ -n "${seen[$key]:-}" ] && continue
  seen[$key]=1
  "setup_${key}"
done

# --- Always: global Claude Code safety net -----------------------------------
# Propagating the repo's deny rules to ~/.claude/settings.json is the whole point
# of this project, so it runs regardless of which agents were selected (even none)
# and is a no-op-safe merge. It only restricts, never grants.
echo
step "Global safety rules"
_claude_merge_deny "$HOME/.claude/settings.json"

# --- Always: executable bits -------------------------------------------------
chmod +x scripts/*.sh bootstrap.sh 2>/dev/null || true
ok "scripts marked executable"

# Optional global plugins last (interactive opt-in; skipped in CI).
install_plugins

echo
printf '%s\n' "${GREEN}${BOLD}✓ Bootstrap complete.${RESET}"
