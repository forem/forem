#!/bin/bash

set -euo pipefail

: ${CONTAINER_REPO:="quay.io/forem"}
: ${CONTAINER_APP:=forem}

export DOCKER_BUILDKIT=1

CONTAINER_BUILD_PATHS_REGEX='^(Containerfile(\.base)?|Dockerfile|\.dockerignore|\.buildkite/.*|\.github/workflows/buildkite\.yml|scripts/(build_containers|create_buildkite_pr_build|entrypoint|bundle)\.sh|\.ruby-version|Gemfile(\.lock)?|vendor/cache/.*|\.nvmrc|package\.json|yarn\.lock|esbuild\.config\.mjs)$'

function should_build_pr_containers {
  if [[ "${FORCE_CONTAINER_BUILD:-}" == "true" || "${FORCE_CONTAINER_BUILD:-}" == "1" ]]; then
    echo "FORCE_CONTAINER_BUILD is set; proceeding with container build."
    return 0
  fi

  local base_branch="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-main}"
  local changed_files=""

  if ! git rev-parse --verify "origin/${base_branch}" >/dev/null 2>&1; then
    git fetch origin "${base_branch}" --depth=50 >/dev/null 2>&1 || true
  fi

  if git rev-parse --verify "origin/${base_branch}" >/dev/null 2>&1; then
    if ! changed_files=$(git diff --name-only "origin/${base_branch}...HEAD" 2>/dev/null); then
      git fetch origin "${base_branch}" --deepen=100 >/dev/null 2>&1 || true
      changed_files=$(git diff --name-only "origin/${base_branch}...HEAD" 2>/dev/null || git diff --name-only "origin/${base_branch}" HEAD 2>/dev/null || echo "__DIFF_FAILED__")
    fi
  else
    echo "Could not resolve origin/${base_branch}; proceeding with container build."
    return 0
  fi

  if [[ "${changed_files}" == "__DIFF_FAILED__" ]]; then
    echo "Could not determine changed files against origin/${base_branch}; proceeding with container build."
    return 0
  fi

  local matching_files
  matching_files=$(echo "${changed_files}" | grep -E "${CONTAINER_BUILD_PATHS_REGEX}" || true)

  if [[ -n "${matching_files}" ]]; then
    echo "Container-relevant files changed relative to ${base_branch}:"
    echo "${matching_files}"
    return 0
  fi

  echo "No container-relevant files changed relative to ${base_branch}. Skipping PR container build."
  return 1
}

function create_pr_containers {

  trap prune_containers ERR INT EXIT

  PULL_REQUEST=$1

  # Pull images if available for caching
  echo "Pulling pull request #${PULL_REQUEST} containers from registry..."
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}" ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":pr-"${PULL_REQUEST}" ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing-"${PULL_REQUEST}" ||:

  # Build the builder image
  echo "Building builder-${PULL_REQUEST} container..."
  docker build --target builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}" \
               --label quay.expires-after=8w \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}" .

  # Build the pull request image
  echo "Building pr-${PULL_REQUEST} container..."
  docker build --target production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}" \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":pr-"${PULL_REQUEST}" \
               --label quay.expires-after=8w \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":pr-"${PULL_REQUEST}" .

  # Build the testing image
  echo "Building testing-$"${PULL_REQUEST}" container..."
  docker build --target testing \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}" \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":pr-"${PULL_REQUEST}" \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":testing-"${PULL_REQUEST}" \
               --label quay.expires-after=8w \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing-"${PULL_REQUEST}" .

  # Push images to Quay
  echo "Pushing pull request #${PULL_REQUEST} containers to registry..."
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}"
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":pr-"${PULL_REQUEST}"
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing-"${PULL_REQUEST}"

}

function create_production_containers {

  trap prune_containers ERR INT EXIT

  # Pull images if available for caching
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":production ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":development ||:

  # Build the builder image
  docker build --target builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder .

  # Build the production image
  docker build --target production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":$(date +%Y%m%d) \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":latest .

  docker build --target production \
               --label quay.expires-after=8w \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":${BUILDKITE_COMMIT:0:7} .

  # Build the testing image
  docker build --target testing \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":testing \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing .

  # Build the development image
  docker build --target development \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":testing \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":development \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":development .

  # Push images to Quay
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":production
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":development
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":$(date +%Y%m%d)
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":${BUILDKITE_COMMIT:0:7}
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":latest

}

function create_release_containers {
  trap prune_containers ERR INT EXIT

  BRANCH=$1

  # Pull images if available for caching
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":production ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":development ||:

  # Build the builder image
  docker build --target builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder .

  # Build the production image
  docker build --target production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":${BUILDKITE_COMMIT:0:7} \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":${BRANCH} .

  # Build the testing image
  docker build --target testing \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":testing \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing-${BRANCH} .

  # Build the development image
  docker build --target development \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":testing \
               --build-arg "VCS_REF=${BUILDKITE_COMMIT}" \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":development-${BRANCH} .

  # If the env var for the git tag doesn't exist or is an empty string, then we
  # won't build a container image for a cut release.
  if [[ -n "${BUILDKITE_TAG+x}" && -n "${BUILDKITE_TAG}" ]]; then
    echo "Buildkite Tag: ${BUILDKITE_TAG}"
    docker build --target production \
                 --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
                 --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
                 --build-arg "VCS_REF=${BUILDKITE_TAG}" \
                 --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":${BUILDKITE_TAG} .
  fi

  # Push images to Quay
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":${BRANCH}
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":development-${BRANCH}
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing-${BRANCH}

}

function prune_containers {

  docker image prune -f

}

if [[ -n "${BUILDKITE+x}" ]]
then
    echo "Branch: ${BUILDKITE_BRANCH:-}"
    echo "PR    : ${BUILDKITE_PULL_REQUEST:-}"
    echo "Commit: ${BUILDKITE_COMMIT:-}"
    echo "Tag   : ${BUILDKITE_TAG:-}"
fi

if [[ -z "${BUILDKITE_BRANCH+x}" ]]; then

    echo "Not running in Buildkite. Building Production Containers..."
    BUILDKITE_COMMIT=$(git rev-parse --short HEAD)
    create_production_containers

elif [ -z "$BUILDKITE_BRANCH" ]; then

    echo "BUILDKITE_BRANCH is set to an empty string! Exiting..."
    exit 1

elif [[ "${BUILDKITE_BRANCH}" = "master" || "${BUILDKITE_BRANCH}" = "main" ]]; then

    echo "Building Production Containers..."
    create_production_containers

elif [[ ${BUILDKITE_BRANCH} = stable* ]]; then

    echo "Building Production Containers for ${BUILDKITE_BRANCH}..."
    create_release_containers "${BUILDKITE_BRANCH}"

else

  if [[ -z "${BUILDKITE_PULL_REQUEST+x}" ]]; then

        echo "BUILDKITE_PULL_REQUEST is unset! Exiting..."
        exit 1

    elif [ -z "$BUILDKITE_PULL_REQUEST" ]; then

        echo "BUILDKITE_PULL_REQUEST is set to an empty string! Exiting..."
        exit 1

    elif ! should_build_pr_containers; then

        exit 0

    else

        echo "Building containers for pull request #${BUILDKITE_PULL_REQUEST}..."
        create_pr_containers "${BUILDKITE_PULL_REQUEST}"

  fi

fi
