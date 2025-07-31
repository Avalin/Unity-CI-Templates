#!/bin/bash
set -e

echo "🔧 Resolving runners..."

# Load runner list from JSON
RUNNER_JSON="${GITHUB_ACTION_PATH}/runners.json"

if [[ ! -f "$RUNNER_JSON" ]]; then
  echo "❌ runners.json not found at $RUNNER_JSON"
  exit 1
fi

mapfile -t GITHUB_RUNNERS < <(jq -r '.githubHostedRunners[]' "$RUNNER_JSON")

is_github_hosted() {
  local label="$1"
  for runner in "${GITHUB_RUNNERS[@]}"; do
    if [[ "$runner" == "$label" ]]; then
      return 0
    fi
  done
  return 1
}

validate_runner() {
  local label="$1"
  echo "🔍 Checking if self-hosted runner label '$label' exists..."
  MATCH=$(gh api repos/"$REPO"/actions/runners \
    --paginate --jq '.runners[].labels[].name' | grep -x "$label" || true)
  if [[ -z "$MATCH" ]]; then
    echo "❌ No self-hosted runners found with label '$label'"
    exit 1
  else
    echo "✅ Valid self-hosted runner label: '$label'"
  fi
}

# ───── Resolve MAIN ─────
MAIN="${MAIN_INPUT:-ubuntu-latest}"
echo "🎯 Resolved MAIN: '$MAIN'"

if is_github_hosted "$MAIN"; then
  echo "✅ '$MAIN' is GitHub-hosted. Skipping validation."
else
  validate_runner "$MAIN"
fi

# ───── Resolve MACOS ─────
MACOS="${MACOS_INPUT:-macos-latest}"
echo "🎯 Resolved MACOS: '$MACOS'"

if is_github_hosted "$MACOS"; then
  echo "✅ '$MACOS' is GitHub-hosted. Skipping validation."
else
  validate_runner "$MACOS"
fi

# Output
echo "main=$MAIN" >> "$GITHUB_OUTPUT"
echo "macos=$MACOS" >> "$GITHUB_OUTPUT"
