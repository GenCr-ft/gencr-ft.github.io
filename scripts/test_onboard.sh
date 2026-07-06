#!/usr/bin/env bash
# ===================================================================
# Unit tests for the public onboarding bootstrap (onboard.sh).
# Sources onboard.sh in library mode (GFT_BOOTSTRAP_LIB=1) so main() does
# not execute, then asserts individual functions. (WI-26, ENG-ADR-087)
# ===================================================================
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

export GFT_BOOTSTRAP_LIB=1
# shellcheck disable=SC1091
source "$REPO_ROOT/onboard.sh"

failed=0
CANON=(aethel gft-platform onboarding agent-ecosystem)

# 1. Canonical workspace validation
for ws in "${CANON[@]}"; do
  if ! is_canonical_workspace "$ws"; then
    echo "FAIL: is_canonical_workspace rejected canonical id '$ws'"; ((failed++))
  fi
done
if is_canonical_workspace "bogus"; then
  echo "FAIL: is_canonical_workspace accepted 'bogus'"; ((failed++))
fi

# 2. Argument parsing (space and = forms)
BOOTSTRAP_WORKSPACE=""
parse_args --workspace onboarding
[[ "$BOOTSTRAP_WORKSPACE" == "onboarding" ]] || { echo "FAIL: --workspace onboarding not parsed (got '$BOOTSTRAP_WORKSPACE')"; ((failed++)); }
BOOTSTRAP_WORKSPACE=""
parse_args --workspace=aethel
[[ "$BOOTSTRAP_WORKSPACE" == "aethel" ]] || { echo "FAIL: --workspace=aethel not parsed (got '$BOOTSTRAP_WORKSPACE')"; ((failed++)); }

# 3. Pinned ref default + override (must be a pinned tag, never a moving branch)
unset GFT_ONBOARDING_REF
default_ref="$(onboarding_ref)"
[[ "$default_ref" == onboarding-v* ]] || { echo "FAIL: default onboarding_ref must be a pinned onboarding-v* tag (got '$default_ref')"; ((failed++)); }
[[ "$default_ref" != "main" && "$default_ref" != "HEAD" ]] || { echo "FAIL: default onboarding_ref must not be a moving branch"; ((failed++)); }
export GFT_ONBOARDING_REF="onboarding-v1.2.3"
[[ "$(onboarding_ref)" == "onboarding-v1.2.3" ]] || { echo "FAIL: GFT_ONBOARDING_REF override ignored"; ((failed++)); }
unset GFT_ONBOARDING_REF

# 3b. Ref safety (argument-injection guard)
for good in onboarding-v1.0.0 main feature/x abc123; do
  is_safe_ref "$good" || { echo "FAIL: is_safe_ref rejected safe ref '$good'"; ((failed++)); }
done
# shellcheck disable=SC2016  # single-quoted payloads are literal on purpose (injection probes)
for bad in "--upload-pack=x" "-x" "" "a;b" 'a$(x)' "a b"; do
  if is_safe_ref "$bad"; then echo "FAIL: is_safe_ref accepted unsafe ref '$bad'"; ((failed++)); fi
done

# 4. Package manager detection returns a known value
pm="$(detect_pkg_mgr)"
case "$pm" in apt|dnf|brew|pacman|unknown) : ;; *) echo "FAIL: detect_pkg_mgr returned unexpected '$pm'"; ((failed++)) ;; esac

# 5. Hand-off command construction
cmd="$(build_handoff_cmd "onboarding")"
[[ "$cmd" == *"gft-onboarding.sh"* && "$cmd" == *"--quickstart"* && "$cmd" == *"--workspace onboarding"* ]] \
  || { echo "FAIL: build_handoff_cmd wrong: '$cmd'"; ((failed++)); }

# 6. No secrets embedded (ENG-ADR-087 invariant)
if grep -qiE 'ghp_|github_pat_|-----BEGIN|token=' "$REPO_ROOT/onboard.sh"; then
  echo "FAIL: onboard.sh appears to contain a secret/token"; ((failed++))
fi

# 7. WI-36 regression: log/warn MUST NOT write to stdout — otherwise they pollute
# command-substitution returns (e.g. dest="$(clone_orchestrator)") and break `cd`.
lout="$(log 'probe' 2>/dev/null)"
[[ -z "$lout" ]] || { echo "FAIL: log() writes to stdout ('$lout') — pollutes \$()-captured returns (the #36 cd crash)"; ((failed++)); }
wout="$(warn 'probe' 2>/dev/null)"
[[ -z "$wout" ]] || { echo "FAIL: warn() writes to stdout ('$wout')"; ((failed++)); }

# 8. WI-36: clone_orchestrator's stdout must be ONLY the destination path. Probe the
# 'existing clone' branch with git stubbed to a no-op, inside an isolated subshell.
_t="$(mktemp -d)"; mkdir -p "$_t/gcd-onboarding-scripts/.git"
probe_dest="$(
  export GFT_PROJECTS_HOME="$_t"
  # shellcheck disable=SC2317  # invoked indirectly by clone_orchestrator
  git() { return 0; }
  clone_orchestrator 2>/dev/null
)"
[[ "$probe_dest" == "$_t/gcd-onboarding-scripts" ]] \
  || { echo "FAIL: clone_orchestrator stdout is not a clean path: '$probe_dest'"; ((failed++)); }
rm -rf "$_t"

if [[ $failed -ne 0 ]]; then
  echo "🔴 test_onboard: $failed check(s) failed."
  exit 1
fi
echo "✓ test_onboard: all checks passed."
