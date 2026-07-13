#!/usr/bin/env bash
# ===================================================================
# Unit tests for the public onboarding bootstrap (onboard.sh).
# Sources onboard.sh in library mode (GFT_BOOTSTRAP_LIB=1) so main() does
# not execute, then asserts individual functions. (WI-387a, ENG-ADR-088 §4)
# ===================================================================
# Tests use `( … )` subshells with local `export`s for isolation on purpose; the
# subshell-scoping (SC2030/SC2031) warnings are expected and intended here.
# shellcheck disable=SC2030,SC2031
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

# 3. Pinned ref default + override (must be a pinned release tag, never a moving branch)
unset GFT_PLT_REF
default_ref="$(plt_ref)"
[[ "$default_ref" == gft-bootstrap-v* ]] || { echo "FAIL: default plt_ref must be a pinned gft-bootstrap-v* tag (got '$default_ref')"; ((failed++)); }
[[ "$default_ref" != "main" && "$default_ref" != "HEAD" ]] || { echo "FAIL: default plt_ref must not be a moving branch"; ((failed++)); }
export GFT_PLT_REF="gft-bootstrap-v9.9.9"
[[ "$(plt_ref)" == "gft-bootstrap-v9.9.9" ]] || { echo "FAIL: GFT_PLT_REF override ignored"; ((failed++)); }
unset GFT_PLT_REF

# 3b. Ref safety (argument-injection guard)
for good in gft-bootstrap-v1.0.0 main feature/x abc123; do
  is_safe_ref "$good" || { echo "FAIL: is_safe_ref rejected safe ref '$good'"; ((failed++)); }
done
# shellcheck disable=SC2016  # single-quoted payloads are literal on purpose (injection probes)
for bad in "--upload-pack=x" "-x" "" "a;b" 'a$(x)' "a b"; do
  if is_safe_ref "$bad"; then echo "FAIL: is_safe_ref accepted unsafe ref '$bad'"; ((failed++)); fi
done

# 4. Package manager detection returns a known value
pm="$(detect_pkg_mgr)"
case "$pm" in apt|dnf|brew|pacman|unknown) : ;; *) echo "FAIL: detect_pkg_mgr returned unexpected '$pm'"; ((failed++)) ;; esac

# 5. studio_home default + override
unset GFT_STUDIO_HOME
[[ "$(studio_home)" == "$HOME/.gft-studio" ]] || { echo "FAIL: studio_home default is not ~/.gft-studio (got '$(studio_home)')"; ((failed++)); }
export GFT_STUDIO_HOME="/tmp/probe-studio"
[[ "$(studio_home)" == "/tmp/probe-studio" ]] || { echo "FAIL: GFT_STUDIO_HOME override ignored"; ((failed++)); }
unset GFT_STUDIO_HOME

# 6. Shim owns NO workspace-clone logic (ENG-ADR-088 §4 invariant 4). The removed
#    functions must be gone; no orchestrator/fixed-home references remain.
for gone in clone_orchestrator build_handoff_cmd onboarding_ref projects_home print_success_summary; do
  if declare -F "$gone" >/dev/null 2>&1; then
    echo "FAIL: removed function '$gone' still present — shim must not clone workspaces"; ((failed++))
  fi
done
if grep -qE 'gcd-onboarding-scripts|gft-onboarding\.sh|GFT_PROJECTS_HOME' "$REPO_ROOT/onboard.sh"; then
  echo "FAIL: onboard.sh still references the removed orchestrator / fixed projects-home"; ((failed++))
fi

# 7. No secrets embedded (ENG-ADR-087/088 invariant)
if grep -qiE 'ghp_|github_pat_|-----BEGIN|token=' "$REPO_ROOT/onboard.sh"; then
  echo "FAIL: onboard.sh appears to contain a secret/token"; ((failed++))
fi

# 8. log/warn MUST NOT write to stdout — otherwise they pollute command-substitution
#    returns (e.g. ws="$(select_workspace)").
lout="$(log 'probe' 2>/dev/null)"
[[ -z "$lout" ]] || { echo "FAIL: log() writes to stdout ('$lout')"; ((failed++)); }
wout="$(warn 'probe' 2>/dev/null)"
[[ -z "$wout" ]] || { echo "FAIL: warn() writes to stdout ('$wout')"; ((failed++)); }

# 9. bootstrap_shared_tooling idempotent fast-path: an existing clone already AT the
#    pinned tag must NOT be re-cloned (no gh call). git stubbed so the tag check passes.
_t9="$(mktemp -d)"; _ghlog9="$_t9/gh.called"
(
  export GFT_STUDIO_HOME="$_t9"
  for r in gcs-plt-tools gcs-plt-gemop gcs-core-governance; do mkdir -p "$_t9/$r/.git"; done
  printf '#!/usr/bin/env bash\n' > "$_t9/gcs-plt-tools/onboard.sh"
  # shellcheck disable=SC2317
  git() { echo "SAME"; return 0; }                    # HEAD == tag always → fast-path skip
  # shellcheck disable=SC2317
  gh() { echo "gh $*" >>"$_ghlog9"; }                 # detect any clone attempt
  mkdir -p "$_t9/bin"; printf '#!/usr/bin/env bash\ntrue\n' > "$_t9/bin/gft"; chmod +x "$_t9/bin/gft"
  export PATH="$_t9/bin:$PATH"
  bootstrap_shared_tooling 2>/dev/null
)
if [[ -f "$_ghlog9" ]] && grep -q 'repo clone' "$_ghlog9"; then
  echo "FAIL: bootstrap_shared_tooling re-cloned a repo already at the pinned tag"; ((failed++))
fi
rm -rf "$_t9"

# 10. bootstrap_shared_tooling dies if gft is NOT on PATH after install (recon risk #3).
_t10="$(mktemp -d)"
(
  export GFT_STUDIO_HOME="$_t10"
  # shellcheck disable=SC2317
  git() { return 1; }                                 # force (re)clone path
  # shellcheck disable=SC2317
  gh() { mkdir -p "$_t10/gcs-plt-tools"; printf '#!/usr/bin/env bash\n' > "$_t10/gcs-plt-tools/onboard.sh"; }
  export PATH="/nonexistent-only"                     # nothing installs a real gft
  bootstrap_shared_tooling 2>/dev/null
) && { echo "FAIL: bootstrap_shared_tooling did not die when gft missing from PATH"; ((failed++)); }
rm -rf "$_t10"

# 11. Full handoff: main() must `exec gft onboard --workspace <ws>` after bootstrap.
#     Everything external is stubbed on PATH; the gft stub records its argv.
_t11="$(mktemp -d)"; _bin="$_t11/bin"; mkdir -p "$_bin" "$_t11/.local/bin"
for c in git curl python3 sudo; do printf '#!/usr/bin/env bash\nexit 0\n' > "$_bin/$c"; chmod +x "$_bin/$c"; done
cat > "$_bin/gh" <<GH
#!/usr/bin/env bash
if [ "\$1 \$2" = "auth status" ]; then exit 0; fi
if [ "\$1 \$2" = "repo clone" ]; then d="\$4"; mkdir -p "\$d"; printf '#!/usr/bin/env bash\ncp "$_bin/gft" "$_t11/.local/bin/gft"\n' > "\$d/onboard.sh"; exit 0; fi
exit 0
GH
chmod +x "$_bin/gh"
cat > "$_bin/gft" <<GFT
#!/usr/bin/env bash
echo "\$@" > "$_t11/gft.argv"
exit 0
GFT
chmod +x "$_bin/gft"
(
  export HOME="$_t11" PATH="$_bin:$_t11/.local/bin:$PATH" GFT_STUDIO_HOME="$_t11/.gft-studio"
  # shellcheck disable=SC1091
  GFT_BOOTSTRAP_LIB=1 source "$REPO_ROOT/onboard.sh"
  main --workspace onboarding
) >/dev/null 2>&1
if [[ ! -f "$_t11/gft.argv" ]] || ! grep -q "onboard --workspace onboarding" "$_t11/gft.argv"; then
  echo "FAIL: main did not exec 'gft onboard --workspace onboarding' (got: $(cat "$_t11/gft.argv" 2>/dev/null))"; ((failed++))
fi
rm -rf "$_t11"

if [[ $failed -ne 0 ]]; then
  echo "🔴 test_onboard: $failed check(s) failed."
  exit 1
fi
echo "✓ test_onboard: all checks passed."
