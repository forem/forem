# Forem AI Context & Rules

This file contains instructions for AI coding assistants working on the Forem codebase (the platform that powers dev.to).
Follow these rules and patterns to ensure high-quality contributions.

## Meta: AI Instruction Synchronization
If you are modifying these agent instructions, you **MUST** replicate your changes across all of Forem's ecosystem AI configuration files to maintain absolute consistency. Forem utilizes multiple environments, and an update to one must happen in all:
- `AGENTS.md`
- `.cursorrules`
- `.windsurfrules`
- `.github/copilot-instructions.md`

## General Philosophy
- **Follow Patterns**: Application consistency is key. Mimic existing patterns for controllers, services, and specs.
- **Smaller is Better**: Prefer atomic, focused modifications over sprawling refactors.
- **Re-usability**: Changes should strengthen Forem as a platform, avoiding DEV-specific hardcoding unless absolutely necessary.
- **Disruption & Clarification**: Always be vigilant about not disrupting existing functionality (e.g., core auth, feed sorting, cache pipelines). If a proposal touches or runs adjacent to a major subsystem, explicitly ask clarifying questions to validate isolation and proactively determine if extra tests are needed to guarantee no side-effects occur.

## Background Workers & Sidekiq
- **Job Storm Prevention**: When enqueuing jobs that might trigger rapidly (e.g., from reactions, comments, or article updates), carefully assess if a debounce lock is required. 
- **Modern Configuration**: Prefer `include Sidekiq::Job` over `Sidekiq::Worker`. Use `sidekiq_options lock: :until_executing, on_conflict: :replace` for coalescing repetitive events.

## Testing Standards
- **Regression Tests are Mandatory**: specific regression tests to verify your code works are required for almost all PRs.
- **Follow Test Patterns**: Use `create(:factory)` syntax (FactoryBot) and standard RSpec expectations.
- **Frontend vs Backend**: We are currently focused on robust backend regression tests. Frontend changes require more manual user review, so clear descriptions of UI changes are vital.
- **Strict Linting Compliance**: Avoid legacy RSpec patterns like `receive_message_chain` and `OpenStruct` which violate existing Forem RuboCop configurations. Use strictly typed relation doubles or explicit anonymous `Class.new` instances for tests instead.
- **Partial Double Verification**: RSpec in Forem is configured with strict partial double verification. Be extremely careful when mocking methods like `is_a?` or chaining methods on Active Record callbacks natively.

## Performance, Callbacks & Caching
- **Fastly Edge Caching & Params**: Forem strictly strips unknown GET query parameters at the Fastly edge layer to prevent cache splintering. If you add a new parameter to a controller, you MUST use an allowed param from `config/fastly/snippets/safe_params_list.vcl` (such as `mode`, `filter`, or `sort`) or explicitly state why you bypassed it.
- **Counter Caches Caveat**: Remember that Rails counter caches (used heavily in Forem for comments/reactions) skip Active Record callbacks (like `after_update_commit`). Do not rely on model callbacks to trigger events based on simple counter increments.
- **Avoid `current_user` and `session_current_user_id` in Cache**:
  - Never use `current_user` or `session_current_user_id` to personalize responses in edge-cached controller actions (`before_action :set_cache_control_headers` / `RequestStore.store[:edge_caching_in_place]`) or inside shared Rails fragment caches (`<% cache ... %>` not keyed by viewer ID) to prevent cross-user cache leaks and private data exposure.
  - At Fastly (`config/fastly/snippets/check_for_remember_user_token_in_cookie_to_set_header.vcl`), cached responses vary only on `X-Loggedin` (`logged-in` vs. `logged-out` via `user_signed_in?`), **not** per-viewer session. Calling `session_current_user_id` bypasses `EdgeCacheSafetyCheck#current_user` and bakes the first signed-in viewer's state into the shared edge/fragment cache for all other signed-in users.
  - **Performance & Query Triage Rule**: When investigating `IS NULL` queries (e.g., `WHERE user_id IS NULL`) or per-user lookups in a controller or view, **first verify whether the action is edge-cached (`set_cache_control_headers`) or rendered inside a shared fragment cache**. If it is on a cached path without `unset_cache_control_headers`, do **not** merely guard the query with `session_current_user_id.present?` — remove the per-viewer server lookup from the cached path altogether and handle viewer-specific state client-side or via an uncached async endpoint.
- **Database Indexes**:
  - Add indexes concurrently using `algorithm: :concurrently`.
  - Use `disable_ddl_transaction!` in the migration class.
  - Ideally, place index additions in their own separate migration files.

## Database & Schema Collisions
- If the `schema.rb` file is modified with extra changes not tied to the migration (due to branch collision, etc.), clean up and manually fix the `schema.rb` file to match the scope of work actually being done in your migration.

## Internationalization (i18n)
- **Update All Locales**: If your change involves new or modified text, you MUST update the corresponding i18n files for ALL supported languages found in `config/locales`.
- **Supported Languages**:
  - `en` (English)
  - `fr` (French)
  - `pt` (Portuguese)
  - And any others present in `config/locales`.

## Frontend
- We are transitioning to a Preact-first frontend.
- Use `app/javascript` and `app/assets` patterns as established.

## Documentation
- If you find documentation that contradicts the codebase, trust the codebase patterns but note the discrepancy.

## Scratch Files
- **Temporary Scripts**: When creating temporary scripts for testing or debugging (e.g., `test_retry.rb` or `test_destroy.rb`), always place them in the `/tmp` directory. You must delete these scratch files as soon as you are done with them to keep the project root clean.

## ML & AI Infrastructure
- **Embeddings**: Forem uses Google's `gemini-embedding-2` model for semantic embeddings.
- **Database Vector Indexes**: We use `pgvector` version `0.8.0+` to support HNSW (Hierarchical Navigable Small World) indexing for high-performance cosine distance queries (`<=>`).
- **Data Integrity**: Vector columns (like `semantic_embedding`) are expensive to compute. Migrations that roll back or drop these columns must raise `ActiveRecord::IrreversibleMigration` to prevent destructive data loss.

## API Changes & Specification Enforcement
- **Document All API Changes**: Any time you modify or add any routes, controller actions, or parameters under `/api/*` (such as adding semantic or fuzzy search endpoints), you **MUST** update or create the corresponding RSWAG documentation specs in `spec/requests/api/v1/docs/*_spec.rb` (or matching version).
- **Regenerate OpenAPI Schema**: After updating the swagger spec files, you **MUST** run the Swagger generation rake task (`bundle exec rake rswag:specs:swaggerize`) to regenerate the `swagger/v1/api_v1.json` file.
- **Do Not Leave Specs Outdated**: Outdated API specifications cause integration failures for external services, gateway clients, and LLM MCP servers. Always treat specs as part of the core delivery.

## Rust Native Extensions (`gems/forem_native`)
- **Architecture (Option A: `magnus` + `forem_core`)**: We methodically rewrite CPU-bound and allocation-heavy Ruby hot paths (e.g., Markdown/Liquid processing, string/tree manipulation, feed scoring math) into Rust inside `gems/forem_native/` as the single source of truth.
- **Strict Two-Layer Separation**:
  - Put all pure algorithm logic in `gems/forem_native/crates/forem_core/` with **zero** Ruby or `magnus` dependencies so it can be unit-tested standalone (`cargo test -p forem_core`) and remains portable to WebAssembly (`wasm32`) or standalone Rust services in future phases.
  - Keep `gems/forem_native/ext/forem_native/` as a thin `magnus` C-ABI wrapper (~15–20 lines per function) that borrows Ruby strings/slices in-place and delegates to `forem_core`.
- **Universal Deployment (Docker, Kamal, Heroku, Render, Railway, AWS, DO, Local)**:
  - `Containerfile` builds `gems/forem_native` in a dedicated `rust-builder` stage so container builds on any architecture (`amd64` / `arm64`) compile fresh from Rust source with zero Rust toolchain in the final production image.
  - Precompiled binaries (`x86_64-linux/forem_native.so`, `arm64-darwin/forem_native.bundle`, `x86_64-darwin/forem_native.bundle`) are committed in `gems/forem_native/lib/forem_native/` for buildpack-only hosts (Heroku, Render Native, Railway), instant CI execution, and zero-dependency local macOS/Linux development (with `ForemNative.load_native!` auto-compiling via `cargo` if needed on other architectures). Rebuild all committed platform binaries whenever adding a new native symbol.
  - Do not add runtime `RubyFallback` modules in `gems/forem_native`, `FeatureFlag` gates, or `ENV` fallback toggles (e.g., `FOREM_NATIVE_FORCE_FALLBACK`). Keep the legacy Ruby calculation in `spec/lib/forem_native_spec.rb` and `lib/tasks/forem_native.rake` as the differential test/benchmark oracle (or, if a Rust function intentionally returns `nil` for out-of-domain inputs, fall through to a private `legacy_<method>` on the calling Ruby class).
- **Verification Requirements**:
  - Run `bundle exec rake forem_native:rust_test` (`cargo test` + `cargo clippy`) and `cargo fmt --all -- --check`.
  - Include differential equivalence specs in `spec/lib/forem_native_spec.rb` asserting `ForemNative` matches the legacy Ruby reference calculation across edge cases and randomized inputs (`1,000+` iterations).
  - Include `benchmark-ips` throughput and `memory_profiler` allocation comparisons (`bundle exec rake forem_native:benchmark`) in PR descriptions. See `docs/rust_native_extensions.md` for full details.
