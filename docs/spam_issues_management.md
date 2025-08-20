# Spam Issues Management

This document describes the automatic spam issue detection and closure system implemented for the Forem repository.

## Overview

The spam issue management system automatically identifies and closes obvious spam GitHub issues while being very conservative to avoid false positives.

## Components

### 1. Service Class: `SpamIssues::CloseObviousSpam`

Located in `app/services/spam_issues/close_obvious_spam.rb`, this service:

- Fetches recent open GitHub issues labeled as "bug"
- Applies conservative detection patterns to identify obvious spam
- Optionally closes spam issues and adds explanatory comments

### 2. Admin Interface

Available in Admin > Tools, this interface allows administrators to:

- Preview spam issues without closing them (dry run)
- Close identified spam issues after confirmation
- View details of identified spam issues

### 3. Rake Task

Run via `rake spam_issues:close_obvious` with optional `--dry-run` flag.

## Detection Patterns

The system uses very conservative patterns to identify spam:

1. **Meaningless titles** with short bodies (e.g., "Aaaa", "test", "spam")
2. **Suspicious IP patterns** that look like spam injection
3. **Random character patterns** suggesting automated spam
4. **Empty template sections** with very short titles

## Usage

### Via Admin Interface

1. Go to Admin > Tools
2. Find the "Close Obvious Spam Issues" section
3. Click "Preview Spam Issues" to see what would be closed
4. Click "Close Issues" to actually close the identified spam

### Via Rake Task

```bash
# Preview spam issues (dry run)
rake spam_issues:close_obvious --dry-run

# Actually close spam issues
DRY_RUN=false rake spam_issues:close_obvious
```

### Via Rails Console

```ruby
# Preview spam issues
result = SpamIssues::CloseObviousSpam.call(dry_run: true)

# Close spam issues
result = SpamIssues::CloseObviousSpam.call(dry_run: false)
```

## Conservative Approach

The system errs heavily on the side of caution:

- Only flags extremely obvious spam to avoid false positives
- Requires multiple indicators for flagging
- Does not close legitimate bug reports, even if they're brief
- Logs all decisions for review

## Error Handling

- Gracefully handles GitHub API errors
- Logs all actions and errors
- Does not fail if GitHub is unavailable
- Provides clear feedback to administrators

## Testing

Comprehensive tests are available in `spec/services/spam_issues/close_obvious_spam_spec.rb` covering:

- Spam detection patterns
- API error handling
- Dry run vs. actual execution
- Edge cases and legitimate content

## Security

- Only admins can access the functionality
- Confirmation required before closing issues
- All actions are logged
- Cannot close legitimate issues due to conservative patterns