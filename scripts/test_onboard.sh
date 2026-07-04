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

# 3. Pinned ref default + override
unset GFT_ONBOARDING_REF
[[ "$(onboarding_ref)" == "main" ]] || { echo "FAIL: default onboarding_ref should be 'main' (got '$(onboarding_ref)')"; ((failed++)); }
export GFT_ONBOARDING_REF="onboarding-v1.2.3"
[[ "$(onboarding_ref)" == "onboarding-v1.2.3" ]] || { echo "FAIL: GFT_ONBOARDING_REF override ignored"; ((failed++)); }
unset GFT_ONBOARDING_REF

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

if [[ $failed -ne 0 ]]; then
  echo "🔴 test_onboard: $failed check(s) failed."
  exit 1
fi
echo "✓ test_onboard: all checks passed."
