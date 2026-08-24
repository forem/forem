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
- **Avoid `current_user` in Cache**: Never use `current_user` objects in cached pages or partials to prevent cache leaks and private data exposure.
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

## API Changes, Schema Regeneration & Specification Enforcement
- **Document All API Changes**: Any time you modify or add routes, controller actions, permitted parameters, or serializers under `/api/*` (such as adding semantic or fuzzy search endpoints, new resource CRUD, or field attributes), you **MUST** update or create the corresponding RSWAG documentation specs in `spec/requests/api/v1/docs/*_spec.rb` and component definitions in `spec/swagger_helper.rb`.
- **Dual V0/V1 & Route Placement**: Standard REST API resources should reside in `config/routes/api.rb` to be accessible across both `v0` and `v1` namespaces, utilizing shared controller concerns in `app/controllers/concerns/api/` with thin `Api::V0` and `Api::V1` controller wrappers.
- **Enrich OpenAPI Schema Descriptions**: In `spec/swagger_helper.rb`, provide detailed, context-rich `description` strings for every object schema and property (including parameter formats like 6-digit hex colors, URL formats, and enum constraints) so external SDKs and LLM agents can effectively use the endpoints.
- **Mandatory Regeneration Step**: After updating swagger spec files or component schemas, you **MUST** execute the Swagger generation task:
  ```bash
  bundle exec rake rswag:specs:swaggerize
  ```
  Verify the changes with `git diff swagger/v1/api_v1.json`.
- **Doc & Regression Verification**: Always run the documentation specs and functional request specs to ensure valid contracts:
  ```bash
  bin/rspec spec/requests/api/v1/docs
  bin/rspec spec/requests/api/v0 spec/requests/api/v1
  ```
- **Never Leave Specs Outdated**: Outdated API specifications cause integration failures for external services, gateway clients, and LLM MCP servers. Always treat specs and generated OpenAPI JSON as core deliverables.