#!/usr/bin/env bash
# ===================================================================
# GenCr@ft Studio - Onboarding Script v1.0
# Idempotent setup for gencr-ft.github.io workspace
# ===================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "=== Onboarding gencr-ft.github.io ==="

# Check Python 3
if ! command -v python3 &>/dev/null; then
  echo "✗ Python 3 is required but not installed." >&2
  exit 1
fi

# Ensure pre-commit is installed
if ! command -v pre-commit &>/dev/null; then
  echo "⚠️  pre-commit not found. Installing..."
  pip install --user pre-commit || { echo "Please install pre-commit manually: pip install pre-commit" >&2; exit 1; }
fi
echo "✓ pre-commit is installed."
pre-commit install --install-hooks

echo "🎉 Onboarding complete! Run ./test.sh to verify contracts."
