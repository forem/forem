# Rust Native Extensions (`forem_native`)

Forem uses an incremental, zero-deployment-overhead architecture (`gems/forem_native/`) to methodically rewrite CPU-bound and allocation-heavy Ruby hot paths into memory-safe Rust as the **single source of truth**.

---

## 1. Architectural Overview: Why Option A (`magnus` + `forem_core`)

To eliminate Ruby VM compute bottlenecks and Garbage Collection (GC) pressure without introducing sidecar containers, network hops, or duplicate code paths to maintain, Forem packages native optimizations as an in-process Ruby C-ABI extension in `gems/forem_native/`.

### Clean Two-Layer Separation (`forem_core` + `forem_native`)
Inside `gems/forem_native/`, the Cargo workspace is strictly divided into two crates:

1. **`crates/forem_core` (Pure Rust Core)**:
   - Accepts and returns standard Rust types (`&[u8]`, `&str`, structs, primitives).
   - Has **zero** dependencies on Ruby, `magnus`, or `rb-sys`.
   - Tested standalone via `cargo test` in milliseconds.
   - **Future-Proof Portability**: Because `forem_core` is pure Rust, the exact same crate powers in-process `magnus` C-ABI extensions today (**Option A**), can compile unchanged to `wasm32-unknown-unknown` if hard fuel-limited sandboxing is ever needed for untrusted plugins (**Option B**), and can be linked directly into standalone Rust query/HTTP services in future phases.
2. **`ext/forem_native` (Thin `magnus` Wrapper)**:
   - ~15–20 lines per function.
   - Borrows Ruby `RString` byte buffers in-place (`unsafe { text.as_slice() }`) with **zero serialization or memory copy** across the VM boundary, calls `forem_core`, and returns standard Ruby values onto Ruby's stack/heap.

---

## 2. Running Everywhere (Heroku, Railway, Render, AWS, DigitalOcean, Docker, Kamal, Local)

`forem_native` runs natively in every deployment environment without needing a feature flag or a duplicate runtime Ruby implementation:

1. **Docker / Kamal / AWS / DigitalOcean / Render / Railway (`Containerfile`)**:
   - `Containerfile` includes a dedicated `FROM rust:1.85-bullseye as rust-builder` multi-stage build that compiles `gems/forem_native` in `--release` mode for the target container architecture (`amd64` or `arm64`) and copies `libforem_native.so` into `${APP_HOME}/gems/forem_native/lib/forem_native/forem_native.so`.
   - Zero Rust compiler toolchain (`rustc`/`cargo`) remains in the final production image.
2. **Heroku / Render Native / Railway Buildpacks & GitHub Actions CI (`x86_64-linux`)**:
   - Because `magnus` + `rb-sys` resolves CRuby C-API symbols dynamically from the host `ruby` process at `dlopen` time (linking only against system `libc`), a single stripped `gems/forem_native/lib/forem_native/x86_64-linux/forem_native.so` (~313 KB) is committed in the repository and verified on every PR by `.github/workflows/forem-native.yml`.
   - Standard Heroku `heroku/ruby` dynos, PaaS buildpacks, and all 30 parallel CI RSpec nodes load `x86_64-linux/forem_native.so` immediately on boot with **zero buildpack changes and zero compile time**.
3. **Local Development (`arm64-darwin`, `x86_64-darwin`, `x86_64-linux`)**:
   - Precompiled `arm64-darwin/forem_native.bundle` (`313 KB`), `x86_64-darwin/forem_native.bundle` (`299 KB`), and `x86_64-linux/forem_native.so` (`311 KB`) binaries are committed directly to the repository (with `RUBY_PLATFORM` version suffixes like `arm64-darwin23` normalized automatically to `arm64-darwin`).
   - Developers cloning the repo on macOS (Apple Silicon or Intel) or Linux do **not** need Rust or `cargo` installed to boot Rails or run tests—it loads the precompiled binary in `<1ms`. Only contributors actively editing `.rs` files inside `gems/forem_native/` (or exotic platforms where `ForemNative.load_native!` auto-compiles via `cargo`) ever invoke the Rust compiler.

---

## 3. Methodical 5-Step Strangler Pattern for Porting Hot Paths

When porting a Ruby method to Rust (manually or via autonomous performance loops), follow this strict 5-step pattern:

### Step 1: Candidate Selection
Target leaf methods on hot spans (high `avg_other_ruby_ms` relative to DB/Redis I/O) that:
- Perform pure CPU work: Markdown/HTML/Liquid parsing, string scanning, regex passes, feed scoring math, or hot serialization helpers.
- Accept primitive inputs (`String`, `Array`, `Hash`, numbers) and return primitive outputs without performing ActiveRecord or Redis I/O inside the loop.

### Step 2: Pure-Rust Implementation in `forem_core` & Thin `magnus` Binding
- Implement the algorithm in `gems/forem_native/crates/forem_core/` with zero-allocation slices where possible and comprehensive Rust `#[test]` unit tests.
- Expose a thin wrapper on `ForemNative::Native` in `gems/forem_native/ext/forem_native/src/lib.rs` and expose the public method on `ForemNative`.

### Step 3: Clean Module Boundary (Single Source of Truth)
Delegate the Ruby call site cleanly to `ForemNative`:

```ruby
module MarkdownProcessor
  module ReadingTime
    WORDS_READ_PER_MINUTE = 275.0

    def self.calculate(content)
      ForemNative.calculate_reading_time(content.to_s)
    end
  end
end
```

### Step 4: Differential Equivalence & Edge-Case Verification
Every ported function **must** include an RSpec suite (`spec/lib/forem_native_spec.rb`) verifying:
- `nil`, empty string, whitespace-only, punctuation-only, Unicode/emoji, and boundary inputs.
- **Differential Equivalence Testing**: Keep the legacy Ruby calculation in the spec as a reference oracle and assert `ForemNative.<method>(input) == legacy_ruby.<method>(input)` across `1,000+` randomized realistic inputs.

### Step 5: Mandatory Benchmark & Allocation Proof
Run `bundle exec rake forem_native:benchmark` and include both `benchmark-ips` throughput and `memory_profiler` allocation results in the PR description.

---

## 4. First Iteration Benchmark: `MarkdownProcessor::ReadingTime`

Previously, `MarkdownProcessor::Parser#calculate_reading_time` ran `@content.split(/\W+/).count`, allocating thousands of transient Ruby `String` and `Array` objects on every article render just to count word tokens.

Benchmarking a ~5,000-word Markdown article (`36,960` bytes) via `bundle exec rake forem_native:benchmark`:

| Metric | Legacy Ruby (`split(/\W+/).count`) | Rust (`magnus` + `forem_core`) | Improvement |
| :--- | :--- | :--- | :--- |
| **Throughput (`benchmark-ips`)** | `723.1 i/s` | `38,732.1 i/s` | **53.56x faster** |
| **Ruby Heap Allocations (10 runs)** | `99,640 objects` (`10.81 MB`) | `0 objects` (`0 B`) | **100% allocation elimination** |
