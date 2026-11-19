#!/usr/bin/env bash
# Check that the committed forem_native binary loads inside the development base image
# (the image Docker, devcontainer and Codespaces contributors use), without cargo.
#
#   scripts/check_forem_native_loads.sh            # this machine's architecture
#   scripts/check_forem_native_loads.sh arm64
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
arch="${1:-$(case "$(uname -m)" in x86_64|amd64) echo amd64 ;; arm64|aarch64) echo arm64 ;; *) uname -m ;; esac)}"
case "$arch" in
  amd64|arm64) ;;
  *) echo "unsupported architecture: $arch (use amd64 or arm64)" >&2; exit 2 ;;
esac
base_image="$(sed -n 's/^FROM \(ghcr\.io\/forem\/ruby[^ ]*\) [Aa][Ss] base$/\1/p' Containerfile | head -1)"
[ -n "$base_image" ] || { echo "could not find the base image in Containerfile" >&2; exit 2; }
echo "==> loading forem_native in $base_image (linux/$arch)"
docker run --rm --platform "linux/$arch" -e FOREM_NATIVE_SKIP_BUILD=1 \
  -v "$PWD/gems/forem_native:/forem_native:ro" "$base_image" \
  ruby -I /forem_native/lib -e '
    require "forem_native"
    abort("not loaded") unless ForemNative.available?
    # A staged lib/forem_native/forem_native.so is tried first; make sure the committed platform binary is what loaded.
    loaded = $LOADED_FEATURES.grep(%r{/lib/forem_native/[^/]+/forem_native\.so\z}).first
    abort("loaded a staged binary, not a committed platform binary: #{$LOADED_FEATURES.grep(/forem_native\.so/).inspect}") unless loaded
    puts "ok: #{loaded} on #{RUBY_PLATFORM} glibc #{`ldd --version`[/\d+\.\d+/]}"'
