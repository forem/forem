#!/usr/bin/env bash
# Rebuild the committed Linux forem_native binaries on the pinned development base
# image (currently Debian bookworm, glibc 2.36), so they load in the Docker,
# devcontainer and Codespaces paths as well as on newer systems.  Uses the
# Containerfile's rust-builder stage, which is what production builds from.
#
#   scripts/build_forem_native_linux.sh            # this machine's architecture
#   scripts/build_forem_native_linux.sh amd64 arm64
#
# Building for a foreign architecture works through QEMU but is slow; build each
# one natively when you can (amd64 on Linux/Intel, arm64 on Apple Silicon).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

host_arch() { case "$(uname -m)" in x86_64|amd64) echo amd64 ;; arm64|aarch64) echo arm64 ;; *) uname -m ;; esac; }
[ "$#" -gt 0 ] || set -- "$(host_arch)"

cid=""
cleanup() { [ -n "$cid" ] && docker rm -f "$cid" >/dev/null 2>&1 || true; }
trap cleanup EXIT

for arch in "$@"; do
  case "$arch" in
    amd64) dir=x86_64-linux ;;
    arm64) dir=aarch64-linux ;;
    *) echo "unsupported architecture: $arch (use amd64 or arm64)" >&2; exit 2 ;;
  esac
  tag="forem-native-build:$arch"
  echo "==> building forem_native for linux/$arch"
  docker buildx build --platform "linux/$arch" --target rust-builder --load -t "$tag" -f Containerfile .
  cid=$(docker create --platform "linux/$arch" "$tag")
  mkdir -p "gems/forem_native/lib/forem_native/$dir"
  docker cp "$cid:/opt/apps/forem/gems/forem_native/target/release/libforem_native.so" \
    "gems/forem_native/lib/forem_native/$dir/forem_native.so"
  docker rm -f "$cid" >/dev/null
  cid=""
  echo "==> gems/forem_native/lib/forem_native/$dir/forem_native.so"
done
