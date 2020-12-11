#!/bin/bash

#
# Adapted parts of this script from the following open source projects:
#   https://github.com/buildkite/trigger-pipeline-action/blob/master/entrypoint.sh
#   MIT License Copyright (c) 2019 Buildkite
#
#   https://github.com/cirrus-actions/rebase/blob/master/entrypoint.sh
#   MIT License Copyright (c) 2019 cirrus-actions
#

set -euo pipefail

# Check for required variables
if [[ -z "${BUILDKITE_API_ACCESS_TOKEN:-}" ]]; then
  echo "You must set the BUILDKITE_API_ACCESS_TOKEN environment variable (e.g. BUILDKITE_API_ACCESS_TOKEN = \"xyz\")"
  exit 1
fi

if [[ -z "${PIPELINE:-}" ]]; then
  echo "You must set the PIPELINE environment variable (e.g. PIPELINE = \"my-org/my-pipeline\")"
  exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Please set the GITHUB_TOKEN env var"
  exit 1
fi

# Get the pull request ID
PULL_REQUEST_ID=${{ github.event.issue.number }}

if [[ -z "${PULL_REQUEST_ID}" || "${PULL_REQUEST_ID}" == "null" ]]; then
  PULL_REQUEST_ID=${{ github.event.number }}
elif [[ -z "${PULL_REQUEST_ID}" || "${PULL_REQUEST_ID}" == "null" ]]; then
  echo "Failed to determine PR Number."
  exit 1
fi

# Gather information about the pull request
echo "Collecting information about PR #${PULL_REQUEST_ID} on ${GITHUB_REPOSITORY}..."

URI=https://api.github.com
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token $GITHUB_TOKEN"

PULL_REQUEST_INFO=$(curl -X GET -s -H "${AUTH_HEADER}" -H "${API_HEADER}" \
          "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${PULL_REQUEST_ID}")

PULL_REQUEST_BASE_REPO=$(echo "${PULL_REQUEST_INFO}" | jq -r .base.repo.full_name)
PULL_REQUEST_BASE_BRANCH=$(echo "${PULL_REQUEST_INFO}" | jq -r .base.ref)

PULL_REQUEST_HEAD_REPO=$(echo "${PULL_REQUEST_INFO}" | jq -r .head.repo.full_name)
PULL_REQUEST_HEAD_BRANCH=$(echo "${PULL_REQUEST_INFO}" | jq -r .head.ref)
PULL_REQUEST_HEAD_SHA=$(echo "${PULL_REQUEST_INFO}" | jq -r .head.sha)

# Gather information about the pull request user
PULL_REQUEST_USER_LOGIN=$(echo "${PULL_REQUEST_INFO}" | jq -r .user.login)
PULL_REQUEST_USER_INFO=$(curl -X GET -s -H "${AUTH_HEADER}" -H "${API_HEADER}" \
            "${URI}/users/${PULL_REQUEST_USER_LOGIN}")

PULL_REQUEST_USER_NAME=$(echo "${PULL_REQUEST_USER_INFO}" | jq -r ".name")
if [[ "${PULL_REQUEST_USER_NAME}" == "null" ]]; then
  PULL_REQUEST_USER_NAME=${PULL_REQUEST_USER_LOGIN}
fi
PULL_REQUEST_USER_NAME="${PULL_REQUEST_USER_NAME} (Buildkite Build)"

PULL_REQUEST_USER_EMAIL=$(echo "${PULL_REQUEST_USER_INFO}" | jq -r ".email")
if [[ "${PULL_REQUEST_USER_EMAIL}" == "null" ]]; then
  PULL_REQUEST_USER_EMAIL="${PULL_REQUEST_USER_LOGIN}@users.noreply.github.com"
fi

# Set Buildkite pipeline variables
COMMENT_USER_LOGIN=$(jq -r ".event.comment.user.login" "${GITHUB_EVENT_PATH}")
ORG_SLUG=$(echo "${PIPELINE}" | cut -d'/' -f1)
PIPELINE_SLUG=$(echo "${PIPELINE}" | cut -d'/' -f2)
MESSAGE_URL=$(jq -r ".event.issue.html_url" "${GITHUB_EVENT_PATH}")
MESSAGE="Build triggered from GitHub Action by ${COMMENT_USER_LOGIN} on ${MESSAGE_URL} for ${PULL_REQUEST_USER_LOGIN}"

# Build JSON payload
JSON=$(
  jq -c -n \
    --arg MESSAGE "${MESSAGE}" \
    --arg PULL_REQUEST_ID "${PULL_REQUEST_ID}" \
    --arg PULL_REQUEST_HEAD_SHA "${PULL_REQUEST_HEAD_SHA}" \
    --arg PULL_REQUEST_BASE_BRANCH "${PULL_REQUEST_BASE_BRANCH}" \
    --arg PULL_REQUEST_HEAD_BRANCH "${PULL_REQUEST_HEAD_BRANCH}" \
    --arg PULL_REQUEST_HEAD_REPO "${PULL_REQUEST_HEAD_REPO}" \
    --arg PULL_REQUEST_USER_NAME "${PULL_REQUEST_USER_NAME}" \
    --arg PULL_REQUEST_USER_EMAIL "${PULL_REQUEST_USER_EMAIL}" \
    '{
      "message": $MESSAGE,
      "commit": $PULL_REQUEST_HEAD_SHA,
      "branch": $PULL_REQUEST_HEAD_BRANCH,
      "pull_request_id": $PULL_REQUEST_ID,
      "pull_request_base_branch": $PULL_REQUEST_BASE_BRANCH,
      "pull_request_repository": $PULL_REQUEST_HEAD_REPO,
      "author": {
        "name": $PULL_REQUEST_USER_NAME,
        "email": $PULL_REQUEST_USER_EMAIL
      }
    }'
)

# Merge in the build environment variables, if they specified any
if [[ "${BUILD_ENV_VARS:-}" ]]; then
  if ! JSON=$(echo "${JSON}" | jq -c --argjson BUILD_ENV_VARS "${BUILD_ENV_VARS}" '. + {env: $BUILD_ENV_VARS}'); then
    echo ""
    echo "Error: BUILD_ENV_VARS provided invalid JSON: ${BUILD_ENV_VARS}"
    exit 1
  fi
fi

# Create the Buildkite pipeline build
echo ""
echo "Creating build with the following payload:"
echo "${JSON}"
RESPONSE=$(
  curl \
    -X POST \
    --fail \
    --silent \
    -H "Authorization: Bearer ${BUILDKITE_API_ACCESS_TOKEN}" \
    "https://api.buildkite.com/v2/organizations/${ORG_SLUG}/pipelines/${PIPELINE_SLUG}/builds" \
    -d "${JSON}"
)

echo ""
echo "Build created:"
echo "$RESPONSE" | jq --raw-output ".web_url"
