# Forem Documentation

This directory contains technical and architectural documentation for the Forem codebase.

For platform-wide guides, getting started tutorials, and API references, please visit the official [Forem Developer Documentation](https://developers.forem.com/).

---

## 📚 Available Documentation

### 🚀 Deployment & Infrastructure
- **[Kamal 2 Deployment Guide](kamal-deployment.md)** - Instructions, architectural overview, and container topology for deploying Forem using Kamal 2 and Kamal Proxy.
- **[Read-Only Database Support](README_READ_ONLY_DATABASE.md)** - Architecture and configuration (`READ_ONLY_DATABASE_URL`) for routing user query execution to read-only database replicas.

### 🛠️ Developer Tools & Services
- **[Developer Tools (`/dev_tools`)](dev_tools.md)** - Guide to the isolated local developer dashboard, instant session spoofing across seeded accounts, and debugging utilities.
- **[GitHub Repository Recap Service](github_repo_recap_service.md)** - Architectural details and usage of the `Ai::GithubRepoRecap` service for generating AI-powered repository activity summaries.

### 🔒 Authentication & Access
- **[Delegated API Access](delegated_access.md)** - Specification for short-lived RFC 9068 access-token JWTs from trusted delegation services without shared secrets.

### 📋 Features & Workflows
- **[Survey Resubmission Feature](survey_resubmission.md)** - Specification, configuration, and model lifecycle methods for the survey resubmission mechanism.

### ⚡ Performance & Optimizations
- **[Rust Native Extensions (`forem_native`)](rust_native_extensions.md)** - In-process Rust native extension architecture (`magnus` + `forem_core`), zero-deployment-overhead fallback design, and the 5-step strangler pattern for porting Ruby hot paths.
- **[Feed Query Optimization](feed_query_optimization.md)** - Query restructuring, eager loading, and performance improvements for home and tag feeds.
- **[Feed Partial Index Optimization](feed_partial_index_optimization.md)** - Database index optimizations and partial index strategies for feed queries.
- **[Feed Impression Accounting](analytics/feed_impressions.md)** - Metric contract, deduplication receipts, batch feedback worker pipeline, and admission controls for feed impression events.
- **[Moderations Performance Optimizations](moderations_performance_optimizations.md)** - Query and indexing optimizations for the `/mod` dashboard to eliminate N+1 queries.

### 🌐 Internationalization (i18n)
- **[Portuguese Internationalization Summary](portuguese_internationalization_summary.md)** - Complete overview and verification of Portuguese i18n implementation.
- **[Locale Analysis](locale_analysis.md)** - Audit of locale file coverage, nesting structure, and missing keys across supported languages.
- **[i18n Implementation Guide](i18n_implementation_guide.md)** - Comprehensive guidelines and best practices for future localization work.

---

## 🛠️ Internal CLI Utilities

The project includes several internal command-line scripts in `bin/` for managing localization and maintenance:

- `bin/locale_file_lookup` - Analyze locale file coverage.
- `bin/create_missing_locales` - Generate missing locale files from base translations.
- `bin/fix_helpers_structure` - Correct nested structure issues in locale YAML files.
- `bin/add_missing_helper_keys` - Populate missing helper keys across languages.

See the [Portuguese Internationalization Summary](portuguese_internationalization_summary.md) for detailed usage examples and commands.
