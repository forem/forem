#!/usr/bin/env bash

set -euo pipefail

workspace="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}"
cd "$workspace"

ruby_version="$(tr -d '[:space:]' < .ruby-version)"
if [[ "$ruby_version" != "3.3.14" ]]; then
  echo "No verified source checksum configured for Ruby ${ruby_version}" >&2
  exit 1
fi

install_root="${RUNNER_TEMP:-/tmp}/ruby-${ruby_version}"
archive="${RUNNER_TEMP:-/tmp}/ruby-${ruby_version}.tar.xz"
configure_options=()

if [[ "${RUNNER_OS:-Linux}" == "macOS" ]]; then
  brew install autoconf bison gdbm libffi libyaml openssl@3 pkg-config readline rust
  export PATH="$(brew --prefix bison)/bin:$PATH"
  configure_options+=("--with-openssl-dir=$(brew --prefix openssl@3)")
  configure_options+=("--with-libyaml-dir=$(brew --prefix libyaml)")
  configure_options+=("--with-gdbm-dir=$(brew --prefix gdbm)")
  configure_options+=("--with-readline-dir=$(brew --prefix readline)")
else
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends \
    autoconf \
    bison \
    build-essential \
    ca-certificates \
    libdb-dev \
    libffi-dev \
    libgdbm-dev \
    libncurses-dev \
    libreadline-dev \
    libssl-dev \
    libyaml-dev \
    pkg-config \
    rustc \
    cargo \
    zlib1g-dev
fi

curl -fsSL "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-${ruby_version}.tar.xz" -o "$archive"
echo "e24ef6d97095a9c42bf8259a2de33a25aac8d92bb48fefdbdc81724b87784854  ${archive}" | shasum -a 256 -c -
mkdir -p "$install_root/source"
tar -xJf "$archive" -C "$install_root/source" --strip-components=1
cd "$install_root/source"
./configure \
  --prefix="$install_root" \
  --enable-shared \
  --enable-yjit \
  --disable-install-doc \
  "${configure_options[@]}"
make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu)"
make install

echo "$install_root/bin" >> "$GITHUB_PATH"
export PATH="$install_root/bin:$PATH"
ruby -e 'abort unless RUBY_VERSION == "3.3.14" && RUBY_PATCHLEVEL == 208; puts "ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"'

if [[ "${1:-ruby-only}" == "bundler-cache" ]]; then
  cd "$workspace"
  bundler_version="$(awk '/^BUNDLED WITH$/{getline; gsub(/^[[:space:]]+/, ""); print; exit}' Gemfile.lock)"
  gem install --no-document bundler --version "$bundler_version"
  bundle config set --local path vendor/bundle
  bundle install --jobs 4 --retry 3
fi
