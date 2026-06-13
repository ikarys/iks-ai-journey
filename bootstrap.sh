#!/usr/bin/env bash
#
# bootstrap.sh — make the repo usable after a fresh clone, per AI agent.
#
# Idempotent. Safe to run repeatedly.
#
# The canonical source of truth is AGENTS.md + canonical/. Each supported agent
# gets a thin adapter so it reads that source the way *it* expects. AGENTS.md is
# already the cross-agent standard (read natively by pi.dev, opencode, Cursor),
# so several agents need little or nothing — only Claude Code needs symlinks.
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
KEYS=(claude pi)
LABELS=(
  "Claude Code — .claude/ symlinks, settings.json"
  "pi.dev      — reads AGENTS.md natively (no files generated)"
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

setup_claude() {
  step "Claude Code"
  link ".claude/CLAUDE.md" "../AGENTS.md"
  link ".claude/rules"     "../canonical/rules"
  link ".claude/skills"    "../canonical/skills"
  link ".claude/commands"  "../canonical/commands"
  # .claude/settings.json (permissions + hooks) is tracked, not generated.
  ok "settings.json + hooks already tracked in .claude/"
}

setup_pi() {
  step "pi.dev"
  # pi loads AGENTS.md from the project root and parent dirs natively, plus a
  # global ~/.pi/agent/AGENTS.md. Nothing to generate in-repo.
  ok   "AGENTS.md at repo root is read natively — nothing to generate"
  info "for global rules, drop an AGENTS.md in ~/.pi/agent/ (your machine)"
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

# --- Always: executable bits -------------------------------------------------
chmod +x scripts/*.sh bootstrap.sh 2>/dev/null || true
ok "scripts marked executable"

# Optional global plugins last (interactive opt-in; skipped in CI).
install_plugins

echo
printf '%s\n' "${GREEN}${BOLD}✓ Bootstrap complete.${RESET}"
