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
