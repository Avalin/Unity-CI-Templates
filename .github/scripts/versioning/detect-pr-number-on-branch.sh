#!/usr/bin/env bash
set -euo pipefail

BRANCH_NAME="$1"
GITHUB_REPOSITORY="$2"
GITHUB_TOKEN="$3"

echo "🔍 Checking for open PRs targeting branch '${BRANCH_NAME}'..."

PR_RESPONSE=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls?head=${GITHUB_REPOSITORY%/*}:${BRANCH_NAME}&state=open")

# Check if the response is an array
IS_ARRAY=$(echo "${PR_RESPONSE}" | jq 'if type == "array" then true else false end')

if [[ "${IS_ARRAY}" == "true" ]]; then
    PR_NUMBER=$(echo "${PR_RESPONSE}" | jq -r '.[0].number // empty')

    if [[ -n "${PR_NUMBER}" && "${PR_NUMBER}" != "null" ]]; then
        PADDED_PR_NUMBER=$(printf "%04d" "${PR_NUMBER}")
        echo "PR-${PADDED_PR_NUMBER}"
    else
        echo ""
    fi
else
    echo "⚠️ Unexpected response from GitHub API:"
    echo "${PR_RESPONSE}"
    echo ""
fi
