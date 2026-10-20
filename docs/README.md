# Forem Documentation

This directory contains documentation for the Forem project.

## 📚 Available Documentation

### Internationalization (i18n)
- **[Portuguese Internationalization Summary](portuguese_internationalization_summary.md)** - Complete overview of Portuguese i18n implementation
- **[Locale Analysis](locale_analysis.md)** - Analysis of locale file coverage and missing files
- **[i18n Implementation Guide](i18n_implementation_guide.md)** - Comprehensive guide for future i18n work

### Performance Optimizations
- **[Feed Query Optimization](feed_query_optimization.md)** - Performance improvements for feed queries
- **[Feed Partial Index Optimization](feed_partial_index_optimization.md)** - Index optimizations for feed performance
- **[Moderations Performance Optimizations](moderations_performance_optimizations.md)** - Performance improvements for moderation features

### Deployment & Infrastructure
- **[Kamal 2 Deployment Guide](kamal-deployment.md)** - Guide for deploying Forem using Kamal 2, container architecture, secrets management, and cloud provider configurations
- **[Read-Only Database Support](README_READ_ONLY_DATABASE.md)** - Setting up and configuring a read-only PostgreSQL replica (`READ_ONLY_DATABASE_URL`), connection pools, and query timeouts

### Architecture & Services
- **[Delegated API Access](delegated_access.md)** - Delegated access mechanics and short-lived RFC 9068 JWT authentication
- **[GitHub Repository Recap Service](github_repo_recap_service.md)** - Overview and usage of the `Ai::GithubRepoRecap` service for summarizing repository activity
- **[Survey Resubmission Feature](survey_resubmission.md)** - Architecture and configuration for allowing users to resubmit surveys

### Developer Tooling
- **[Developer Tools Dashboard](dev_tools.md)** - Local `/dev_tools` interface for session spoofing and utility scripts

## 🛠️ i18n Tools

The project includes several tools for managing internationalization:

- `bin/locale_file_lookup` - Analyze locale file coverage
- `bin/create_missing_locales` - Create missing locale files
- `bin/fix_helpers_structure` - Fix nested structure issues
- `bin/add_missing_helper_keys` - Add missing helper keys

See the [Portuguese Internationalization Summary](portuguese_internationalization_summary.md) for detailed usage examples.
