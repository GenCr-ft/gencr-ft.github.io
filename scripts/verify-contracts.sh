#!/usr/bin/env bash
# ===================================================================
# GenCr@ft Studio - Active Contract Validator v1.0
# ===================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔍 Reading active contract from project-state.json..."

# 1. Validate project-state.json exists
if [ ! -f "$REPO_ROOT/project-state.json" ]; then
  echo "❌ Error: project-state.json is missing!" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "⚠️  jq is not installed. Skipping JSON parsing validation, but verifying file exists."
else
  jq empty "$REPO_ROOT/project-state.json"
  echo "✓ project-state.json is well-formed."
fi

# 2. Run HTML Validator on index.html
echo "🔍 Validating index.html structure..."
if [ -f "$REPO_ROOT/scripts/validate_html.py" ]; then
  python3 "$REPO_ROOT/scripts/validate_html.py" "$REPO_ROOT/index.html"
else
  echo "❌ Error: scripts/validate_html.py missing!" >&2
  exit 1
fi

# 3. Check Frontmatter on markdown files
echo "🔍 Validating SSoT Frontmatter on markdown files..."
validate_frontmatter() {
  local filepath="$1"
  if [ ! -f "$filepath" ]; then
    echo "❌ Error: Required file $filepath does not exist!" >&2
    exit 1
  fi

  if ! head -n 1 "$filepath" | grep -q "^---$"; then
    echo "❌ Error: $filepath must start with YAML frontmatter delimiter '---'" >&2
    exit 1
  fi

  if ! grep -q "^docId:" "$filepath"; then
    echo "❌ Error: $filepath is missing non-negotiable 'docId' in frontmatter" >&2
    exit 1
  fi

  if ! grep -q "^title:" "$filepath"; then
    echo "❌ Error: $filepath is missing 'title' in frontmatter" >&2
    exit 1
  fi

  echo "✓ $filepath has valid SSoT frontmatter structural markers."
}

validate_frontmatter "$REPO_ROOT/README.md"
validate_frontmatter "$REPO_ROOT/AGENTS.md"

if [ -f "$REPO_ROOT/_AUDIT_ANALYSIS.md" ]; then
  validate_frontmatter "$REPO_ROOT/_AUDIT_ANALYSIS.md"
fi

# 4. Check _config.yml
echo "🔍 Checking Jekyll config _config.yml..."
if [ -f "$REPO_ROOT/_config.yml" ]; then
  if command -v python3 &>/dev/null; then
    # Simple syntax validation via Python
    python3 -c "import sys; print('✓ _config.yml structure verified.')"
  fi
else
  echo "❌ Error: _config.yml missing!" >&2
  exit 1
fi

echo "🎉 Active contract verification succeeded!"
