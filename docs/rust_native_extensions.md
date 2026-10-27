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
Delegate the Ruby call site cleanly to `ForemNative`. Do **not** add runtime `FeatureFlag` checks, `ENV` toggles (such as `FOREM_NATIVE_FORCE_FALLBACK`), or duplicate `ForemNative::RubyFallback` modules inside `gems/forem_native`:

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

- **When a Rust function handles 100% of inputs** (e.g., `MarkdownProcessor::ReadingTime.calculate`), call `ForemNative.<method>` directly and delete the old runtime Ruby code from `app/`.
- **When a Rust function intentionally handles a strict common-case domain and returns `nil` for quirky/out-of-domain inputs** (e.g., `ForemNative.color_brightness` returning `nil` for malformed hex strings or `NaN`/`Infinity` multipliers so Ruby's rescue/formatting quirks apply), keep the legacy edge-case handler as a private method in the host Ruby class (`ForemNative.color_brightness(...) || legacy_brightness(...)`) so constants/regexes remain in one place rather than duplicating them inside `gems/forem_native`.
- **Update all committed precompiled binaries** (`x86_64-linux/forem_native.so`, `arm64-darwin/forem_native.bundle`, `x86_64-darwin/forem_native.bundle`) whenever adding a new native symbol so every platform exports the full `ForemNative::Native` API without needing `respond_to?` guards.

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

---

## 5. Second Iteration Pattern: Coarse-Grained Service & Query-Pipeline Kernels (`forem_core::feed`)

While leaf string/color/URL helpers (Section 4) eliminate isolated micro-allocations, request-level service pipelines such as `/stories/feed` (`Stories::FeedsController#show` -> `FeedConfig.select_for_feed` -> `FeedConfig#score_sql` -> `Articles::Feeds::Custom#default_home_feed` -> `show.json.jbuilder`) suffer from **compound multi-step overhead**:
- The same `UserActivity#recently_viewed_articles` JSONB array is scanned and parsed via `String#to_datetime` (`Date._parse`) hundreds of times per request across `FeedConfig.active_user?`, `FeedConfig#score_sql`, and `Articles::Feeds::Custom#calculate_dynamic_shuffle_count`.
- Dynamic SQL scoring expression assembly (`FeedConfig#score_sql`) concatenates intermediate follow arrays, quotes tag/label literals in loops, formats 768-float `pgvector` embeddings via `Array#join(',')` (769 string allocations per call), and runs regex `String#squish` passes over multi-KB SQL strings.
- Post-query candidate ranking (`Articles::Feeds::Custom#weighted_shuffle`) and story serialization (`Article#video_duration_in_minutes`) allocate intermediate tuple arrays, boxed float sort keys, and `ActiveSupport::Duration` hashes on every story.

To optimize service and query-builder pipelines in a general-purpose, reusable way without disrupting ActiveRecord models or controller contracts, follow the **Two-Tier Composable Primitives + Pipeline Kernel Pattern** in `crates/forem_core/src/feed.rs`:

1. **Tier 1 — General-Purpose Composable Primitives**:
   Expose standalone, zero-allocation building blocks on `forem_core::feed` and `ForemNative` that any feed, digest, notification, or query builder can call independently:
   - `ForemNative.activity_distinct_days_since(entries, cutoff_time)` & `ForemNative.activity_pageviews_since(entries, cutoff_time)` — zero-allocation ISO-8601/SQL timestamp parsing + Howard Hinnant civil-date window aggregation.
   - `ForemNative.dynamic_shuffle_count(most_recent_timestamp, now_time, weight)` & `ForemNative.weighted_shuffle(items, shuffle_weight)` — candidate re-ranking and recency-weighted window sizing.
   - `ForemNative.sql_int_list(ids, empty_fallback)`, `ForemNative.sql_string_array_literal(items, pg_type)`, `ForemNative.sql_vector_literal(values)`, & `ForemNative.sql_squish(sql)` — reusable SQL literal/array/vector/whitespace primitives.
   - `ForemNative.format_video_duration(seconds)` — zero-`ActiveSupport::Duration` duration formatting for feed JSON serialization.
2. **Tier 2 — Single-Pass Coarse-Grained Pipeline Kernel**:
   Compose those Tier 1 primitives into a single-pass Rust pipeline (`ForemNative.feed_config_score_sql` -> `forem_core::feed::build_feed_config_score_sql`) that borrows the Ruby `FeedConfig` weight vector and `UserActivity` arrays in-place (`unsafe { arr.as_slice() }`), scans `recently_viewed_articles` once, and writes the entire multi-KB SQL scoring expression into a single pre-allocated Rust `String`.

Benchmarking the complete `/stories/feed` custom feed pipeline (`FeedConfig.active_user?` + `FeedConfig#score_sql` with 768-float embedding + `calculate_dynamic_shuffle_count` + `weighted_shuffle` + 35x `Article#video_duration_in_minutes`) via `bundle exec rake forem_native:benchmark`:

| Metric | Legacy Ruby (`/stories/feed` pipeline) | Rust (`magnus` + `forem_core::feed`) | Improvement |
| :--- | :--- | :--- | :--- |
| **Throughput (`benchmark-ips`)** | `663.7 i/s` | `13,675.9 i/s` | **20.61x faster** |
| **Ruby Heap Allocations (10 runs)** | `66,159 objects` (`5.49 MB`) | `1,760 objects` (`169.1 KB`) | **97.3% fewer objects / 96.9% less memory** |

---

## 6. Maintaining Embedded Static Datasets & Removed Gems

Several Ruby gems have been fully removed from `Gemfile` (or mirrored in `forem_core`) after porting their functionality into `gems/forem_native`. Because some of these libraries wrap static upstream standards or registries, contributors should be aware of which modules are pure math versus which embed static data tables that may occasionally be refreshed:

| Gem / Standard | Status in `Gemfile` | `forem_core` Module & Data File | Needs Periodic Data Updates? |
| :--- | :--- | :--- | :--- |
| **`wcag_color_contrast`** | **Removed** | `crates/forem_core/src/color.rs` (`wcag_contrast_ratio`) | **No** — Implements the fixed W3C WCAG 2.x relative luminance & contrast ratio formula. Pure math; no external data tables. |
| **`gemoji`** | **Removed** | `crates/forem_core/src/emoji.rs` & `emoji_data.rs` (`EMOJI_BLOB`, `EMOJI_ENTRIES`) | **Occasionally (Unicode releases)** — Upstream [`github/gemoji`](https://github.com/github/gemoji) (`db/emoji.json`) is a static JSON mapping of `:shortcode:` aliases to UTF-8 emoji sequences. Only changes when adopting a new Unicode Emoji release or adding custom shortcodes. |
| **`emoji_regex`** | **Removed** | `crates/forem_core/src/emoji.rs` & `emoji_data.rs` (`RGI_EMOJI_BLOB`, `RGI_EMOJI_ENTRIES`) | **Occasionally (Unicode releases)** — Upstream `emoji_regex` is a static list of Unicode `RGI_Emoji` sequences derived from Unicode's [`emoji-sequences.txt`](https://unicode.org/Public/emoji/latest/emoji-sequences.txt) and [`emoji-zwj-sequences.txt`](https://unicode.org/Public/emoji/latest/emoji-zwj-sequences.txt). Only changes when adopting a new Unicode Emoji release. |
| **`public_suffix`** | Transitive dep of `addressable` | `crates/forem_core/src/url.rs` & `psl_data.rs` (`PSL_BLOB`, `PSL_ENTRIES`) | **When `public_suffix` is bumped** — Mirrors the Mozilla Public Suffix List (`data/list.txt` inside the `public_suffix` gem). Regenerate `psl_data.rs` whenever `bundle update public_suffix` updates `Gemfile.lock`. |

### How to Refresh `emoji_data.rs` or `psl_data.rs`
1. **Updating `emoji_data.rs` (Unicode Emoji / Gemoji)**:
   - `EMOJI_BLOB` and `EMOJI_ENTRIES` store all sorted `(alias, raw_utf8)` pairs from GitHub's `db/emoji.json` (`https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json`), where each `u32` entry packs `(offset << 11) | (alias_len << 5) | raw_len`.
   - `RGI_EMOJI_BLOB` and `RGI_EMOJI_ENTRIES` store all unique UTF-8 `RGI_Emoji` sequences sorted by `(first_char_utf8_bytes, Reverse(byte_len), full_utf8_bytes)`, where each `u32` entry packs `(offset << 8) | (byte_len << 2) | (first_char_utf8_len - 1)`.
2. **Updating `psl_data.rs` (Mozilla Public Suffix List)**:
   - `PSL_BLOB` and `PSL_ENTRIES` store all ASCII rules from `PublicSuffix::List.default` (`Gem.loaded_specs["public_suffix"].full_gem_path + "/data/list.txt"`), sorted by rule label bytes with each `u32` entry packing `(offset << 10) | (len << 2) | kind`.
3. **Rebuilding Precompiled Binaries**:
   - After updating any `.rs` data file in `crates/forem_core/src/`, run `bundle exec rake forem_native:rust_test` and recompile the committed platform binaries (`arm64-darwin/forem_native.bundle`, `x86_64-darwin/forem_native.bundle`, and `x86_64-linux/forem_native.so`).
