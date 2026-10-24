require "fileutils"
require "rbconfig"
require_relative "../../lib/forem_native/builder"

# Zero-deployment-overhead `extconf.rb` for `forem_native`:
# 1. If a precompiled binary for the target platform is already present, or if
#    `cargo` is not installed, writes a no-op `Makefile` so `bundle install`
#    always succeeds immediately.
# 2. If no precompiled binary is present and `cargo` is available, generates
#    a `Makefile` that compiles the Rust workspace in `--release` mode.

dlext = ForemNative::Builder.dlext
skip_build = ForemNative::Builder.precompiled_binary_exists? ||
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
  gem_root = ForemNative::Builder::GEM_ROOT
  manifest_path = ForemNative::Builder::MANIFEST_PATH
  artifact_path = ForemNative::Builder.cargo_artifact_path
  target_bin = ForemNative::Builder.extension_binary_path

  File.write("Makefile", <<~MAKEFILE)
    RUBYARCHDIR ?= #{RbConfig::CONFIG['sitearchdir']}

    all:
    \tcd "#{gem_root}" && cargo build --release --manifest-path "#{manifest_path}"
    \tmkdir -p "#{File.dirname(target_bin)}"
    \tcp "#{artifact_path}" "#{target_bin}"

    install:
    \tif [ -n "$(RUBYARCHDIR)" ]; then mkdir -p "$(RUBYARCHDIR)/forem_native" && cp "#{target_bin}" "$(RUBYARCHDIR)/forem_native/forem_native.#{dlext}"; fi

    clean:
    \tcd "#{gem_root}" && cargo clean --manifest-path "#{manifest_path}"
  MAKEFILE
end
