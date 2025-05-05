#!/usr/bin/env bash
set -euo pipefail

BRANCH_NAME="$1"
GITHUB_REPOSITORY="$2"
GITHUB_TOKEN="$3"

echo "🔍 Checking for open PRs targeting branch '${BRANCH_NAME}'..."

PR_RESPONSE=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls?head=${GITHUB_REPOSITORY%/*}:${BRANCH_NAME}&state=open")

PR_NUMBER=$(echo "${PR_RESPONSE}" | jq -r '.[0].number // empty')

if [[ -n "${PR_NUMBER}" ]]; then
    PADDED_PR_NUMBER=$(printf "%04d" "${PR_NUMBER}")
    echo "PR-${PADDED_PR_NUMBER}"
else
    echo ""
fi