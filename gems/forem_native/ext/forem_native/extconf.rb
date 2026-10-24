require "fileutils"
require "rbconfig"
require_relative "../../lib/forem_native/builder"

# Zero-deployment-overhead `extconf.rb` for `forem_native`:
# 1. If a precompiled binary for the target platform is already present, or if
#    `cargo` is not installed (e.g., on a stock Heroku dyno or minimal Docker
#    builder layer), writes a no-op `Makefile` so `bundle install` always succeeds.
# 2. If `cargo` is available and `FOREM_NATIVE_SKIP_BUILD` is not set, generates
#    a `Makefile` that compiles the Rust workspace in `--release` mode and installs
#    the resulting shared library (`.bundle` / `.so`).

dlext = ForemNative::Builder.dlext
precompiled_platform_bin = ForemNative::Builder.extension_binary_path(platform_dir: RUBY_PLATFORM)
precompiled_default_bin = ForemNative::Builder.extension_binary_path
skip_build = File.exist?(precompiled_platform_bin) ||
  File.exist?(precompiled_default_bin) ||
  !ForemNative::Builder.cargo_available?

if skip_build
  File.write("Makefile", <<~MAKEFILE)
    all:
    \t@true
    install:
    \t@true
    clean:
    \t@true
  MAKEFILE
else
  manifest_path = ForemNative::Builder::MANIFEST_PATH
  artifact_path = ForemNative::Builder.cargo_artifact_path
  target_bin = ForemNative::Builder.extension_binary_path

  File.write("Makefile", <<~MAKEFILE)
    RUBYARCHDIR ?= #{RbConfig::CONFIG['sitearchdir']}

    all:
    \tcargo build --release --manifest-path "#{manifest_path}"
    \tmkdir -p "#{File.dirname(target_bin)}"
    \tcp "#{artifact_path}" "#{target_bin}"

    install:
    \tif [ -n "$(RUBYARCHDIR)" ]; then mkdir -p "$(RUBYARCHDIR)/forem_native" && cp "#{target_bin}" "$(RUBYARCHDIR)/forem_native/forem_native.#{dlext}"; fi

    clean:
    \tcargo clean --manifest-path "#{manifest_path}"
  MAKEFILE
end
