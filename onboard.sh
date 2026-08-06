#!/usr/bin/env bash
# ===================================================================
# GenCr@ft Studio — one-line onboarding bootstrap (ENG-ADR-088 §4)
#
# Public entry point:
#   curl -fsSL https://gencr-ft.github.io/onboard.sh | bash
# Non-interactive / CI:
#   curl -fsSL https://gencr-ft.github.io/onboard.sh | bash -s -- --workspace <id>
#
# Thin, secretless shim (ENG-ADR-088 Phase 1 — shared-tooling bootstrap): installs
# prerequisites, authenticates via GitHub CLI device flow, clones the shared tooling
# repos into ~/.gft-studio at a pinned release tag, installs the global `gft` CLI via
# its owner (gcs-plt-tools), then hands off to `gft onboard` (Phase 2 — workspace
# onboarding). The shim contains NO workspace-clone logic and NO secrets.
#
# Workspaces: aethel | gft-platform | onboarding | agent-ecosystem
# Env: GFT_STUDIO_HOME (default ~/.gft-studio), GFT_PLT_REF (pinned release tag).
# ===================================================================

BOOTSTRAP_WORKSPACE=""

# The shared-tooling repos cloned once into ~/.gft-studio (ENG-ADR-088 §Repository
# Classification). gcs-plt-tools owns the global `gft` CLI; gcs-plt-gemop supplies the
# gem/skill library that `gft onboard` symlinks into each workspace's .claude; and
# gcs-core-governance is the SSoT.
SHARED_TOOLING_REPOS="gcs-plt-tools gcs-plt-gemop gcs-core-governance"

# All human-facing logging goes to STDERR so functions that "return" a value via
# stdout (select_workspace) are never polluted when captured with $(...).
log()  { printf '\033[0;34m[onboard]\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[0;33m[onboard]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[0;31m[onboard]\033[0m %s\n' "$*" >&2; exit 1; }
ok()   { printf '\033[0;32m[onboard]\033[0m %s\n' "$*" >&2; }

studio_home() { printf '%s' "${GFT_STUDIO_HOME:-$HOME/.gft-studio}"; }

# Pinned release tag — the sole trust anchor between this public shim and the shared
# tooling (ENG-ADR-088 §Pinned-Tag Governance). A single tag name shared across the 3
# repos. NEVER a moving branch. Advancing the pin is a deliberate, reviewed change to
# this file.
#
# RELEASE COORDINATION: to advance the pin, tag ALL THREE shared repos
# (gcs-plt-tools, gcs-plt-gemop, gcs-core-governance) with the new tag BEFORE merging
# the bump here. GitHub has no atomic cross-repo tagging; if a tag is missing from any
# repo, bootstrap_shared_tooling fails loudly (die) on the missing clone — safe, but
# it means a half-tagged release breaks onboarding until all three are tagged.
plt_ref() { printf '%s' "${GFT_PLT_REF:-gft-bootstrap-v1.0.1}"; }

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

# Phase 1: clone the shared-tooling repos into ~/.gft-studio at the pinned tag and
# install the global `gft` CLI via its owner (gcs-plt-tools). Idempotent. No workspace
# or project-repo cloning happens here — that is Phase 2, owned by `gft onboard`.
bootstrap_shared_tooling() {
  local home ref repo dest
  home="$(studio_home)"; ref="$(plt_ref)"
  is_safe_ref "$ref" || die "Refusing unsafe GFT_PLT_REF '$ref'."
  mkdir -p "$home"
  for repo in $SHARED_TOOLING_REPOS; do
    dest="$home/$repo"
    # Fast path: an existing clone whose HEAD is already the pinned tag's commit —
    # no network, no re-clone. (Local-only check; safe on shallow clones.)
    if [ -d "$dest/.git" ] \
       && git -C "$dest" rev-parse --verify -q "refs/tags/${ref}^{commit}" >/dev/null 2>&1 \
       && [ "$(git -C "$dest" rev-parse -q HEAD 2>/dev/null)" = "$(git -C "$dest" rev-parse -q "refs/tags/${ref}^{commit}" 2>/dev/null)" ]; then
      log "$repo already at $ref."
      continue
    fi
    # Otherwise — absent, stale/non-git, or a different ref — (re)clone fresh at the
    # pinned tag. Re-cloning always lands on the exact ref, avoiding the shallow-clone
    # `git fetch <tag>` pitfall (the tag is not created locally by a bare fetch).
    if [ -e "$dest" ]; then
      log "Updating $repo to $ref…"
      rm -rf "$dest" || die "Could not remove stale tooling at $dest. Check permissions and re-run."
    fi
    log "Fetching shared tooling: $repo (pinned $ref)…"
    gh repo clone "GenCr-ft/$repo" "$dest" -- \
        --branch "$ref" --depth 1 --quiet -c advice.detachedHead=false 2>/dev/null \
      || die "Download of $repo failed. Ask your team lead to confirm your GitHub account is in the GenCr-ft org, then re-run."
  done
  # Install the global `gft` CLI via the canonical owner (unchanged mechanism).
  log "Installing the gft CLI…"
  ( cd "$home/gcs-plt-tools" && bash onboard.sh ) \
    || die "gft installation failed. Re-run this command, or share the output with #devops-support."
  # CRITICAL: gft must be on PATH in THIS process before we exec it.
  export PATH="$HOME/.local/bin:$PATH"
  command -v gft >/dev/null 2>&1 \
    || die "gft was installed but is not on PATH. Restart your terminal and run: gft onboard"
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

  # Non-interactive with no workspace: prerequisites + auth are done; tell the user
  # which command finishes the setup for their assigned workspace, and exit cleanly.
  if [ -z "$ws" ]; then
    ok "Prerequisites are installed and you are authenticated with GitHub."
    log "To set up a workspace, run one of these (pick the one you were assigned):"
    local w
    for w in aethel gft-platform onboarding agent-ecosystem; do
      log "  curl -fsSL https://gencr-ft.github.io/onboard.sh | bash -s -- --workspace $w"
    done
    exit 0
  fi

  log "Setting up shared tooling and the gft CLI (this can take a few minutes on first run)…"
  bootstrap_shared_tooling

  # Phase 2 hand-off: `gft onboard` owns workspace cloning, editor + .claude
  # provisioning, per-user machine setup, and the completion summary. Replace this
  # process with it so its exit status is the script's exit status.
  log "Handing off to: gft onboard --workspace $ws"
  exec gft onboard --workspace "$ws"
}

# Library guard: tests source this file with GFT_BOOTSTRAP_LIB=1 to assert individual
# functions without executing the bootstrap.
if [ "${GFT_BOOTSTRAP_LIB:-0}" != "1" ]; then
  main "$@"
fi
