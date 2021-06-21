#!/bin/bash

set -euo pipefail

: ${CONTAINER_REPO:="quay.io/forem"}
: ${CONTAINER_APP:=forem}

function create_pr_containers {

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
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}" .

  # Build the pull request image
  echo "Building pr-${PULL_REQUEST} container..."
  docker build --target production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}" \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":pr-"${PULL_REQUEST}" \
               --label quay.expires-after=8w \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":pr-"${PULL_REQUEST}" .

  # Build the testing image
  echo "Building testing-$"${PULL_REQUEST}" container..."
  docker build --target testing \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}" \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":pr-"${PULL_REQUEST}" \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":testing-"${PULL_REQUEST}" \
               --label quay.expires-after=8w \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing-"${PULL_REQUEST}" .

  # Push images to Quay
  echo "Pushing pull request #${PULL_REQUEST} containers to registry..."
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder-"${PULL_REQUEST}"
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":pr-"${PULL_REQUEST}"
  docker push "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing-"${PULL_REQUEST}"

}

function create_production_containers {

  # Pull images if available for caching
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":production ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing ||:
  docker pull "${CONTAINER_REPO}"/"${CONTAINER_APP}":development ||:

  # Build the builder image
  docker build --target builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":builder .

  # Build the production image
  docker build --target production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":$(date +%Y%m%d) \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":${BUILDKITE_COMMIT:0:7} \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":latest .

  # Build the testing image
  docker build --target testing \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":testing \
               --tag "${CONTAINER_REPO}"/"${CONTAINER_APP}":testing .

  # Build the development image
  docker build --target development \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":builder \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":production \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":testing \
               --cache-from="${CONTAINER_REPO}"/"${CONTAINER_APP}":development \
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


function prune_containers {

  docker image prune -f

}

trap prune_containers ERR INT EXIT

if [ ! -v BUILDKITE_BRANCH ]; then

    echo "Not running in Buildkite. Building Production Containers..."
    BUILDKITE_COMMIT=$(git rev-parse --short HEAD)
    create_production_containers

elif [ -z "$BUILDKITE_BRANCH" ]; then

    echo "BUILDKITE_BRANCH is set to an empty string! Exiting..."
    exit 1

elif [[ "${BUILDKITE_BRANCH}" = "master" || "${BUILDKITE_BRANCH}" = "main" ]]; then

    echo "Building Production Containers..."
    create_production_containers

else

  if [ ! -v BUILDKITE_PULL_REQUEST ]; then

        echo "BUILDKITE_PULL_REQUEST is unset! Exiting..."
        exit 1

    elif [ -z "$BUILDKITE_PULL_REQUEST" ]; then

        echo "BUILDKITE_PULL_REQUEST is set to an empty string! Exiting..."
        exit 1

    else

        echo "Building containers for pull request #${BUILDKITE_PULL_REQUEST}..."
        create_pr_containers "${BUILDKITE_PULL_REQUEST}"

  fi

fi
