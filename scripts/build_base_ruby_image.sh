#!/usr/bin/env bash
# Must be bash (or compatible) for read -a and array access.

set -eu

if [ "$(pwd)" != "$(git rev-parse --show-toplevel)" ]; then
	echo "This script must be run from the root of the Forem repository!" > /dev/stderr
	exit 1
fi

BUILD_PLATFORMS="${BUILD_PLATFORMS:-linux/amd64,linux/arm64}"
RUBY_VERSION="${RUBY_VERSION:-$(cat .ruby-version-next)}"
IMAGE="ghcr.io/forem/ruby:${RUBY_VERSION}"

if [ -z "${SKIP_PUSH:-}" ]; then
	PUSH_FLAG="--push"
fi

IFS=',' read -ra BUILD_PLATFORMS_ARR <<< "${BUILD_PLATFORMS}"
for platform in "${BUILD_PLATFORMS_ARR[@]}"; do
  if docker pull --platform "${platform}" "${IMAGE}"; then
    echo "Image ${IMAGE} already exists for platform ${platform}, but it will be overridden by this script." > /dev/stderr
  fi
done

if [ -z "${EXTERNAL_QEMU:-}" ]; then
	docker run --rm --privileged multiarch/qemu-user-static \
		--reset \
		-p yes \
		--credential yes
fi

# shellcheck disable=SC2086
docker buildx build \
	--platform "${BUILD_PLATFORMS}" \
	-f Containerfile.base \
	-t "${IMAGE}"\
	${PUSH_FLAG:-} \
	--build-arg RUBY_VERSION="${RUBY_VERSION}" \
	.
