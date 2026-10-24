require_relative "lib/forem_native/version"

Gem::Specification.new do |spec|
  spec.name = "forem_native"
  spec.version = ForemNative::VERSION
  spec.authors = ["Forem"]
  spec.email = ["yo@dev.to"]

  spec.summary = "In-process Rust native extensions (Magnus + rb-sys) for Forem hot paths with pure-Ruby fallback"
  spec.description = <<~DESC
    Provides memory-safe, zero-copy Rust native extensions for CPU-bound and
    allocation-heavy hot paths in Forem, backed by the pure-Rust `forem_core` crate
    and automatic pure-Ruby fallback when precompiled binaries are absent.
  DESC
  spec.homepage = "https://github.com/forem/forem"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "Cargo.toml",
    "Cargo.lock",
    ".cargo/config.toml",
    "crates/**/*",
    "ext/**/*",
    "lib/**/*",
    "README.md",
  ].reject { |f| File.directory?(f) || f.start_with?("target/") }

  spec.require_paths = ["lib"]
  spec.extensions = ["ext/forem_native/extconf.rb"]
end
