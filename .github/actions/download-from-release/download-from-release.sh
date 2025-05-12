#!/bin/bash
set -euo pipefail

# ────────────────────────────
# Inputs
# ────────────────────────────
PROJECT_NAME="${1:?Missing project name}"
VERSION="${2:?Missing version}"
GITHUB_REPOSITORY="${3:?Missing repository}"
GITHUB_TOKEN="${4:?Missing GitHub token}"
HAS_COMBINED_ARTIFACTS="${5:?Missing hasCombinedArtifacts flag (true/false)}"
REQUIRED_BUILD_TARGETS_JSON="${6:?Missing required build targets JSON}"

PROJECT_NAME="$(echo "$PROJECT_NAME" | xargs)"
SANITIZED_PROJECT_NAME="$(echo "$PROJECT_NAME" | sed 's/[^a-zA-Z0-9._-]/_/g')"

VERSION="$(echo "$VERSION" | xargs)"
GITHUB_REPOSITORY="$(echo "$GITHUB_REPOSITORY" | xargs)"
GITHUB_TOKEN="$(echo "$GITHUB_TOKEN" | xargs)"
HAS_COMBINED_ARTIFACTS="$(echo "$HAS_COMBINED_ARTIFACTS" | xargs)"

DEST_DIR="deployment-artifacts/${SANITIZED_PROJECT_NAME}-${VERSION}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Starting Release Asset Download"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Project                   : ${SANITIZED_PROJECT_NAME}"
echo "🔹 Version                   : ${VERSION}"
echo "🔹 Repository                : ${GITHUB_REPOSITORY}"
echo "🔹 Has Combined              : ${HAS_COMBINED_ARTIFACTS}"
echo "🔹 Target Download Directory : ${DEST_DIR}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "${DEST_DIR}"

# ────────────────────────────
# Fetch Release Metadata
# ────────────────────────────
echo "📡 Fetching release assets from GitHub CLI"
RELEASE_DATA=$(GH_TOKEN="${GITHUB_TOKEN}" gh api -H "Accept: application/vnd.github+json" \
  "repos/${GITHUB_REPOSITORY}/releases/tags/${VERSION}")

# ────────────────────────────
# Extract URLs
# ────────────────────────────
echo "🔍 Extracting asset download URLs..."
ASSETS=$(echo "${RELEASE_DATA}" | jq -r '.assets[] | "\(.name) \(.url)"')

if [[ -z "${ASSETS}" ]]; then
  echo "❌ No assets found for tag ${VERSION}"
  exit 1
fi

# ────────────────────────────
# Download & Extract
# ────────────────────────────
found_combined_artifact=false

if [[ "${HAS_COMBINED_ARTIFACTS}" == "true" ]]; then
  echo "🛠️ Only downloading combined artifact..."

  while read -r NAME URL; do
    if [[ "${NAME}" == *-all-platforms.zip ]]; then
      echo "⬇️ Downloading combined artifact: ${NAME}"
      GH_TOKEN="${GITHUB_TOKEN}" gh api "${URL}" \
        -H "Accept: application/octet-stream" > "${DEST_DIR}/${NAME}"

      echo "📂 Extracting ${NAME} into ${DEST_DIR}"
      unzip -q "${DEST_DIR}/${NAME}" -d "${DEST_DIR}"
      rm "${DEST_DIR}/${NAME}"
      found_combined_artifact=true
      break
    fi
  done <<< "${ASSETS}"

  if [[ "${found_combined_artifact}" == "false" ]]; then
    echo "❌ Expected combined artifact (-all-platforms.zip) but none was found!"
    exit 1
  fi

else
  echo "📦 Downloading and extracting per-build-target artifacts..."

  REQUIRED_BUILD_TARGETS=($(echo "${REQUIRED_BUILD_TARGETS_JSON}" | jq -r '.[]'))

  for TARGET in "${REQUIRED_BUILD_TARGETS[@]}"; do
    ARTIFACT_NAME="${SANITIZED_PROJECT_NAME}-${VERSION}-${TARGET}.zip"
    ARTIFACT_URL=$(echo "${ASSETS}" | awk -v name="${ARTIFACT_NAME}" '$1 == name {print $2}')

    if [[ -z "${ARTIFACT_URL}" ]]; then
      echo "⚠️ Warning: Artifact ${ARTIFACT_NAME} not found in release assets."
      continue
    fi

    echo "⬇️ Downloading: ${ARTIFACT_NAME}"
    GH_TOKEN="${GITHUB_TOKEN}" gh api "${ARTIFACT_URL}" \
      -H "Accept: application/octet-stream" > "${DEST_DIR}/${ARTIFACT_NAME}"

    echo "📂 Extracting ${ARTIFACT_NAME} to ${DEST_DIR}/${SANITIZED_PROJECT_NAME}-${VERSION}-${TARGET}"
    mkdir -p "${DEST_DIR}/${SANITIZED_PROJECT_NAME}-${VERSION}-${TARGET}"
    unzip -q "${DEST_DIR}/${ARTIFACT_NAME}" -d "${DEST_DIR}/${SANITIZED_PROJECT_NAME}-${VERSION}-${TARGET}"
    rm "${DEST_DIR}/${ARTIFACT_NAME}"
  done
fi

echo "✅ Finished downloading release assets to: ${DEST_DIR}"