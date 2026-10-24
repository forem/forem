# Rust Native Extensions (`forem_native`)

Forem uses an incremental, zero-deployment-overhead architecture (`gems/forem_native/`) to methodically rewrite CPU-bound and allocation-heavy Ruby hot paths into memory-safe Rust.

---

## 1. Architectural Overview: Why Option A (`magnus` + `forem_core`)

To eliminate Ruby VM compute bottlenecks and Garbage Collection (GC) pressure without introducing sidecar containers, network hops, or mandatory Rust toolchains on production hosts, Forem packages native optimizations as an in-process Ruby C-ABI extension in `gems/forem_native/`.

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

## 2. Zero Deployment Overhead on Docker, Kamal, and Heroku

A core requirement of `forem_native` is that **no deployment environment (Docker, Kamal, Heroku, or contributor laptops without Rust) ever breaks or slows down if `rustc`/`cargo` is absent**:

1. **Graceful `extconf.rb`**: When `ext/forem_native/extconf.rb` runs during gem installation, it checks whether a precompiled binary is already present or whether `cargo` is installed. If `cargo` is not installed (or `FOREM_NATIVE_SKIP_BUILD=1` is set), `extconf.rb` emits a no-op `Makefile` so `bundle install` always succeeds.
2. **Automatic Pure-Ruby Fallback (`ForemNative::RubyFallback`)**: When `require "forem_native"` runs, it attempts to load the compiled shared library (`forem_native.bundle` / `forem_native.so`). If absent, `ForemNative.available?` returns `false` and all methods transparently delegate to `ForemNative::RubyFallback`.
3. **Runtime Flipper Feature Flag**: Every Rails integration point guards execution with `ForemNative.available? && FeatureFlag.enabled?(:native_<feature>)`, allowing instant runtime toggling without redeploying.

---

## 3. Methodical 5-Step Strangler Pattern for Porting Hot Paths

When porting a Ruby method to Rust (manually or via autonomous performance loops), follow this strict 5-step pattern:

### Step 1: Candidate Selection
Target leaf methods on hot spans (high `avg_other_ruby_ms` relative to DB/Redis I/O) that:
- Perform pure CPU work: Markdown/HTML/Liquid parsing, string scanning, regex passes, feed scoring math, or hot serialization helpers.
- Accept primitive inputs (`String`, `Array`, `Hash`, numbers) and return primitive outputs without performing ActiveRecord or Redis I/O inside the loop.

### Step 2: Pure-Rust Implementation in `forem_core` & Thin `magnus` Binding
- Implement the algorithm in `gems/forem_native/crates/forem_core/` with zero-allocation slices where possible and comprehensive Rust `#[test]` unit tests.
- Expose a thin wrapper on `ForemNative::Native` in `gems/forem_native/ext/forem_native/src/lib.rs` and mirror the method in `ForemNative` and `ForemNative::RubyFallback`.

### Step 3: Clean Module Boundary & Dual-Path Feature Flag
Extract the Ruby call site into a clean module boundary gated by both `ForemNative.available?` and a `FeatureFlag`:

```ruby
module MarkdownProcessor
  module ReadingTime
    WORDS_READ_PER_MINUTE = 275.0
    FEATURE_FLAG = :native_reading_time

    def self.calculate(content)
      text = content.to_s
      if ForemNative.available? && FeatureFlag.enabled?(FEATURE_FLAG)
        ForemNative.calculate_reading_time(text)
      else
        legacy_ruby_calculate(text)
      end
    end

    def self.legacy_ruby_calculate(content)
      word_count = content.to_s.split(/\W+/).count
      (word_count / WORDS_READ_PER_MINUTE).ceil
    end
  end
end
```

### Step 4: Differential Equivalence & Edge-Case Verification
Every ported function **must** include an RSpec suite (`spec/lib/forem_native_spec.rb`) verifying:
- `nil`, empty string, whitespace-only, punctuation-only, Unicode/emoji, and boundary inputs.
- **Differential Equivalence Testing**: Assert `ForemNative::Native.<method>(input) == ForemNative::RubyFallback.<method>(input)` across `1,000+` randomized realistic inputs.
- Both states of the Flipper `FeatureFlag` (`enabled` and `disabled`) plus `ForemNative.with_fallback`.

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
