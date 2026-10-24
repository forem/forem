# `forem_native` — In-Process Rust Native Extensions for Forem

`forem_native` is Forem's monorepo Rust native extension workspace (`gems/forem_native/`), built on [`magnus`](https://github.com/matsadler/magnus) and [`rb-sys`](https://github.com/oxidize-rb/rb-sys).

## Workspace Architecture

The Cargo workspace is intentionally split into two layers to support both immediate in-process Ruby C-ABI acceleration (**Option A**) and future portability to WebAssembly sandboxes (**Option B**) or standalone Rust services:

```text
gems/forem_native/
├── Cargo.toml                  # Cargo workspace root
├── crates/
│   └── forem_core/             # Pure-Rust core library (ZERO Ruby/magnus dependencies)
│       └── src/
│           ├── lib.rs
│           └── markdown.rs     # Zero-allocation Markdown/text algorithms
├── ext/
│   └── forem_native/           # Thin Magnus C-ABI wrapper (~15-20 lines per function)
│       ├── extconf.rb          # Zero-overhead builder (precompiled binary / cargo / no-op fallback)
│       └── src/lib.rs          # Exposes `ForemNative::Native` to CRuby
└── lib/
    ├── forem_native.rb         # Public API, binary loader, and automatic fallback dispatch
    └── forem_native/
        ├── builder.rb          # Cargo build helper
        ├── ruby_fallback.rb    # 100% behaviorally equivalent pure-Ruby fallback
        └── version.rb
```

1. **`crates/forem_core`**: Pure Rust library crate accepting standard Rust slices (`&[u8]`, `&str`) and returning standard Rust types. Contains zero `magnus` or Ruby VM dependencies, allowing standalone `cargo test` execution in milliseconds and future compilation to `wasm32-unknown-unknown` or native Rust HTTP/query workers.
2. **`ext/forem_native`**: Thin `magnus` wrapper that borrows Ruby `RString` byte buffers in-place (`unsafe { text.as_slice() }`) with zero copy across the VM boundary and returns immediate Ruby values.
3. **`lib/forem_native`**: Loads the compiled shared library (`.bundle` on macOS, `.so` on Linux) when present and falls back transparently to `ForemNative::RubyFallback` if the native binary is unavailable.

## Zero-Deployment-Overhead Design (Docker, Kamal, Heroku)

- **`extconf.rb` Never Fails Without Rust**: If a precompiled platform binary is already staged or if `cargo` is not installed on the target host (such as the production Docker builder or a standard Heroku Ruby dyno), `extconf.rb` writes a no-op `Makefile` so `bundle install` succeeds with zero build overhead.
- **Dual-Path Feature Flag + Automatic Fallback**: Every Rails call site checks `ForemNative.available? && FeatureFlag.enabled?(:native_<feature>)` before invoking `ForemNative`, and `ForemNative` itself falls back to `ForemNative::RubyFallback` if the native binary is not loaded.

## Common Commands

From the repository root:

```bash
# Compile the Rust native extension into gems/forem_native/lib/forem_native/
bundle exec rake forem_native:compile

# Run pure-Rust unit tests and Clippy lints
bundle exec rake forem_native:rust_test

# Run RSpec differential equivalence and fallback specs
bundle exec rspec spec/lib/forem_native_spec.rb spec/services/markdown_processor/reading_time_spec.rb

# Run benchmark-ips throughput and memory_profiler allocation benchmarks
bundle exec rake forem_native:benchmark
```
