#!/usr/bin/env bash
# ===================================================================
# GenCr@ft Studio — one-line onboarding bootstrap (ENG-ADR-087)
#
# Public entry point:
#   curl -fsSL https://gencr-ft.github.io/onboard.sh | bash
# Non-interactive / CI:
#   curl -fsSL https://gencr-ft.github.io/onboard.sh | bash -s -- --workspace <id>
#
# Thin, secretless shim (Approach A): installs prerequisites, authenticates via
# GitHub CLI device flow, clones the pinned gcd-onboarding-scripts orchestrator,
# and hands off to gft-onboarding.sh. All heavy install/config logic lives in
# the orchestrator; the global `gft` CLI is installed by gcs-plt-tools (single
# owner). This script contains NO secrets.
#
# Workspaces: aethel | gft-platform | onboarding | agent-ecosystem
# Env: GFT_PROJECTS_HOME (default ~/gft_studio), GFT_ONBOARDING_REF (pinned ref,
#      default "main" until the first onboarding-vX.Y.Z release tag is cut).
# ===================================================================

ONBOARDING_REPO="GenCr-ft/gcd-onboarding-scripts"
BOOTSTRAP_WORKSPACE=""

# All human-facing logging goes to STDERR so that functions which "return" a value
# via stdout (e.g. clone_orchestrator, select_workspace) are never polluted when
# captured with $(...). Regression guard: scripts/test_onboard.sh checks 7 & 8.
log()  { printf '\033[0;34m[onboard]\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[0;33m[onboard]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[0;31m[onboard]\033[0m %s\n' "$*" >&2; exit 1; }
ok()   { printf '\033[0;32m[onboard]\033[0m %s\n' "$*" >&2; }

projects_home() { printf '%s' "${GFT_PROJECTS_HOME:-$HOME/gft_studio}"; }
# Pinned release tag — the sole trust anchor between this public shim and the
# orchestrator (ENG-ADR-087). NEVER defaults to a moving branch. Advancing the
# pin is a deliberate, reviewed change to this file.
onboarding_ref() { printf '%s' "${GFT_ONBOARDING_REF:-onboarding-v1.0.1}"; }

# Reject refs that could smuggle a git option (leading '-') or shell/path tricks.
is_safe_ref() {
  case "${1:-}" in
    -*|"") return 1 ;;
    *[!A-Za-z0-9._/-]*) return 1 ;;
    *) return 0 ;;
  esac
}

is_canonical_workspace() {
  case "${1:-}" in
    aethel|gft-platform|onboarding|agent-ecosystem) return 0 ;;
    *) return 1 ;;
  esac
}

print_workspaces() { printf '  %s\n' aethel gft-platform onboarding agent-ecosystem; }

detect_pkg_mgr() {
  if command -v apt-get >/dev/null 2>&1; then echo apt
  elif command -v dnf >/dev/null 2>&1; then echo dnf
  elif command -v brew >/dev/null 2>&1; then echo brew
  elif command -v pacman >/dev/null 2>&1; then echo pacman
  else echo unknown; fi
}

pkg_install() {
  local pkg="$1" pm
  pm="$(detect_pkg_mgr)"
  case "$pm" in
    apt)    sudo apt-get update -qq && sudo apt-get install -y "$pkg" ;;
    dnf)    sudo dnf install -y "$pkg" ;;
    brew)   brew install "$pkg" ;;
    pacman) sudo pacman -S --noconfirm "$pkg" ;;
    *)      return 1 ;;
  esac
}

ensure_cmd() {
  local cmd="$1" pkg="${2:-$1}"
  command -v "$cmd" >/dev/null 2>&1 && return 0
  log "Installing missing prerequisite: $cmd"
  pkg_install "$pkg" || die "Could not install '$cmd' automatically. Install it and re-run."
}

# GitHub CLI needs a dedicated apt repo on Debian/Ubuntu; other managers ship it.
ensure_gh() {
  command -v gh >/dev/null 2>&1 && return 0
  log "Installing GitHub CLI (gh)…"
  case "$(detect_pkg_mgr)" in
    apt)
      sudo mkdir -p -m 755 /etc/apt/keyrings
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      sudo apt-get update -qq && sudo apt-get install -y gh ;;
    dnf)    sudo dnf install -y gh ;;
    brew)   brew install gh ;;
    pacman) sudo pacman -S --noconfirm github-cli ;;
    *)      die "Install GitHub CLI manually: https://github.com/cli/cli#installation, then re-run." ;;
  esac
  command -v gh >/dev/null 2>&1 || die "GitHub CLI install failed. See https://github.com/cli/cli#installation"
}

# Interactive device-flow login. No secrets are stored by this script.
ensure_gh_auth() {
  if gh auth status >/dev/null 2>&1; then
    log "GitHub CLI already authenticated."
    return 0
  fi
  log "Authenticating with GitHub (device flow — you will get a one-time code)…"
  # Least-privilege: clone-only bootstrap needs repo read + org membership, not workflow/admin.
  gh auth login --hostname github.com --git-protocol https --scopes "repo,read:org" --web \
    || die "GitHub authentication failed. Re-run after 'gh auth login'."
}

# Clone (or refresh) the orchestrator at the pinned ref. Idempotent.
clone_orchestrator() {
  local home ref dest
  home="$(projects_home)"; ref="$(onboarding_ref)"; dest="$home/gcd-onboarding-scripts"
  is_safe_ref "$ref" || die "Refusing unsafe GFT_ONBOARDING_REF '$ref'."
  mkdir -p "$home"
  # Fast path: an existing clone whose HEAD is already the pinned tag's commit —
  # no network, no re-clone. (Local-only check; safe on shallow clones.)
  if [ -d "$dest/.git" ] \
     && git -C "$dest" rev-parse --verify -q "refs/tags/${ref}^{commit}" >/dev/null 2>&1 \
     && [ "$(git -C "$dest" rev-parse -q HEAD 2>/dev/null)" = "$(git -C "$dest" rev-parse -q "refs/tags/${ref}^{commit}" 2>/dev/null)" ]; then
    log "Onboarding toolkit already at $ref."
    printf '%s' "$dest"
    return 0
  fi
  # Otherwise — absent, stale/non-git, or a different (older) ref — (re)clone fresh at
  # the pinned tag. Re-cloning is ~220 KiB and always lands on the exact ref, which
  # avoids the shallow-clone `git fetch <tag>` pitfall (tag not created locally).
  if [ -e "$dest" ]; then
    log "Updating the onboarding toolkit to $ref…"
    rm -rf "$dest"
  fi
  log "Fetching the onboarding toolkit (pinned $ref)…"
  gh repo clone "$ONBOARDING_REPO" "$dest" -- \
      --branch "$ref" --depth 1 --quiet -c advice.detachedHead=false 2>/dev/null \
    || die "Download failed. Ask your team lead to confirm your GitHub account is in the GenCr-ft org, then re-run."
  printf '%s' "$dest"
}

build_handoff_cmd() {
  printf 'bash gft-onboarding.sh --quickstart --workspace %s' "$1"
}

# Echoes the chosen workspace, or empty string for the safe non-interactive default.
select_workspace() {
  if [ -n "$BOOTSTRAP_WORKSPACE" ]; then printf '%s' "$BOOTSTRAP_WORKSPACE"; return 0; fi
  # Prompt only when /dev/tty can actually be opened for read AND write. This works
  # under `curl | bash` (stdin is the pipe, so `[ -t 0/1 ]` are unreliable) and stays
  # quiet in true non-interactive contexts where /dev/tty exists but can't be opened.
  if { : >/dev/tty; } 2>/dev/null && { : </dev/tty; } 2>/dev/null; then
    {
      printf 'Select a workspace:\n'
      print_workspaces
      printf 'Workspace [aethel]: '
    } >/dev/tty
    local choice=""
    read -r choice </dev/tty || choice=""
    printf '%s' "${choice:-aethel}"
  else
    printf ''
  fi
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --workspace)   BOOTSTRAP_WORKSPACE="${2:-}"; shift 2 ;;
      --workspace=*) BOOTSTRAP_WORKSPACE="${1#*=}"; shift ;;
      -h|--help)     printf 'Usage: onboard.sh [--workspace <id>]\nWorkspaces:\n'; print_workspaces; return 0 ;;
      *)             warn "Unknown argument: $1"; printf 'Usage: onboard.sh [--workspace <id>]\nWorkspaces:\n' >&2; print_workspaces >&2; die "Unrecognized flag '$1'." ;;
    esac
  done
}

main() {
  set -euo pipefail
  parse_args "$@"
  log "GenCr@ft Studio onboarding bootstrap"

  ensure_cmd git git
  ensure_cmd curl curl
  ensure_gh
  ensure_cmd python3 python3
  ensure_gh_auth

  local ws; ws="$(select_workspace)"
  if [ -n "$ws" ] && ! is_canonical_workspace "$ws"; then
    warn "Unknown workspace '$ws'. Valid workspaces:"
    print_workspaces >&2
    die "Choose one of the four canonical workspaces."
  fi

  local dest; dest="$(clone_orchestrator)"
  cd "$dest" || die "Could not enter $dest."

  if [ -z "$ws" ]; then
    ok "Prerequisites are installed and the onboarding toolkit is ready."
    log "To finish setting up a workspace, run one of these (pick the one you were assigned):"
    local w
    for w in aethel gft-platform onboarding agent-ecosystem; do
      log "  curl -fsSL https://gencr-ft.github.io/onboard.sh | bash -s -- --workspace $w"
    done
    exit 0
  fi

  log "Setting up your '$ws' workspace — installing the gft CLI, tools, and repositories…"
  log "(this can take a few minutes on first run)"
  if bash gft-onboarding.sh --quickstart --workspace "$ws"; then
    print_success_summary "$ws"
  else
    die "Workspace setup hit an error above. Re-run this same command, or share the log with #devops-support."
  fi
}

# Friendly, non-technical completion summary printed to stdout at the very end.
print_success_summary() {
  local ws="$1" gft_bin="${HOME}/.local/bin/gft" ver=""
  if [ -x "$gft_bin" ]; then
    ver="$("$gft_bin" version 2>/dev/null || "$gft_bin" --version 2>/dev/null || true)"
    ver="$(printf '%s' "$ver" | head -1)"
  fi
  printf '\n\033[0;32m✓ GenCr@ft onboarding complete — you are set up.\033[0m\n\n'
  printf '  Workspace:    %s\n' "$ws"
  printf '  Your repos:   %s\n' "$(projects_home)"
  if [ -x "$gft_bin" ]; then
    printf '  gft CLI:      installed at %s%s\n' "$gft_bin" "${ver:+  ($ver)}"
  else
    printf '  gft CLI:      installed (see the messages above for details)\n'
  fi
  printf '\n  What to do next:\n'
  printf '   1. Close and reopen your terminal   (or run:  source ~/.bashrc)\n'
  printf '   2. Confirm everything is healthy:   gft doctor\n'
  printf '   3. Explore your repositories in:    %s\n' "$(projects_home)"
  printf '\n  Questions or something looks off? Ask in #devops-support.\n\n'
}

# Library guard: tests source this file with GFT_BOOTSTRAP_LIB=1 to assert
# individual functions without executing the bootstrap.
if [ "${GFT_BOOTSTRAP_LIB:-0}" != "1" ]; then
  main "$@"
fi
