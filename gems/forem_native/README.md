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
│           ├── color.rs        # Zero-allocation hex color brightness scaling
│           ├── lib.rs
│           └── markdown.rs     # Zero-allocation Markdown/text algorithms
├── ext/
│   └── forem_native/           # Thin Magnus C-ABI wrapper (~15-20 lines per function)
│       ├── extconf.rb          # Precompiled binary / cargo Makefile generator
│       └── src/lib.rs          # Exposes `ForemNative::Native` to CRuby
└── lib/
    ├── forem_native.rb         # Public API and native binary loader
    └── forem_native/
        ├── builder.rb          # Cargo build helper and platform resolver
        ├── arm64-darwin/
        │   └── forem_native.bundle # Precompiled macOS Apple Silicon binary
        ├── x86_64-darwin/
        │   └── forem_native.bundle # Precompiled macOS Intel binary
        ├── x86_64-linux/
        │   └── forem_native.so     # Precompiled Linux binary for Heroku / Render / Railway / CI
        └── version.rb
```

1. **`crates/forem_core`**: Pure Rust library crate accepting standard Rust slices (`&[u8]`, `&str`) and returning standard Rust types. Contains zero `magnus` or Ruby VM dependencies, allowing standalone `cargo test` execution in milliseconds and future compilation to `wasm32-unknown-unknown` or native Rust HTTP/query workers.
2. **`ext/forem_native`**: Thin `magnus` wrapper that borrows Ruby `RString` byte buffers in-place (`unsafe { text.as_slice() }`) with zero copy across the VM boundary and returns immediate Ruby values.
3. **`lib/forem_native`**: Loads the compiled shared library (`.bundle` on macOS, `.so` on Linux) directly—with Rust as the single source of truth in production.

## Running Everywhere (Heroku, Railway, Render, AWS, DigitalOcean, Docker, Kamal, Local)

- **Container Deployments (`Containerfile` / Docker / Kamal / AWS / DigitalOcean / Render / Railway)**: A dedicated `FROM rust:1.85-bullseye as rust-builder` multi-stage layer compiles `gems/forem_native` in `--release` mode for the target architecture (`amd64` or `arm64`) and copies `libforem_native.so` into the app image with zero Rust compiler overhead in the final production image.
- **Buildpack Deployments & CI (Heroku, Render Native Ruby, Railway, GitHub Actions)**: A precompiled, stripped `lib/forem_native/x86_64-linux/forem_native.so` (~313 KB, dynamically resolving Ruby C-API symbols from the host process) is committed directly to the repository so `git push heroku main` and CI nodes load the native extension immediately with zero compile step or Rust buildpack required.
- **Local Development (macOS Apple Silicon, macOS Intel, Linux)**: Precompiled `arm64-darwin/forem_native.bundle`, `x86_64-darwin/forem_native.bundle`, and `x86_64-linux/forem_native.so` binaries are committed in the repository, so developers do **not** need Rust or `cargo` installed locally unless they are actively modifying `.rs` files in `gems/forem_native/`. If a developer runs on an unlisted platform, `ForemNative.load_native!` automatically invokes `ForemNative::Builder.compile!` via `cargo` on first boot.

## Common Commands

From the repository root:

```bash
# Compile the Rust native extension into gems/forem_native/lib/forem_native/
bundle exec rake forem_native:compile

# Run pure-Rust unit tests and Clippy lints
bundle exec rake forem_native:rust_test

# Run RSpec differential equivalence specs
bundle exec rspec spec/lib/forem_native_spec.rb spec/services/markdown_processor/reading_time_spec.rb

# Run benchmark-ips throughput and memory_profiler allocation benchmarks
bundle exec rake forem_native:benchmark
```
