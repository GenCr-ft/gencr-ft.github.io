#!/usr/bin/env bash
# ===================================================================
# GenCr@ft Studio - Test & Contract Verification Script v1.0
# ===================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "=== Running Website Verification & Active Contracts ==="

# 1. Run Active Contract Validator
if [ -f "./scripts/verify-contracts.sh" ]; then
  bash "./scripts/verify-contracts.sh"
else
  echo "❌ Error: verify-contracts.sh script missing!" >&2
  exit 1
fi

echo "🎉 All tests and contracts passed successfully!"
