# Scheduled Automations

This document describes the Scheduled Automations feature, which allows community bots to automatically generate and publish content on a recurring schedule.

## Overview

The Scheduled Automations system enables community bots to:
- Run AI-powered services on a schedule (hourly, daily, weekly, or custom intervals)
- Automatically create drafts or publish articles
- Add custom instructions to guide AI content generation
- Manage multiple automations per bot

## Architecture

### Components

1. **Model**: `ScheduledAutomation` - Stores automation configuration and schedule
2. **Service**: `ScheduledAutomations::Executor` - Executes automations and creates articles
3. **Worker**: `ScheduledAutomations::ProcessWorker` - Cron job that runs every 10 minutes
4. **Admin UI**: Controllers and views for managing automations

### Database Schema

```ruby
create_table :scheduled_automations do |t|
  t.references :user, null: false, foreign_key: true, index: true
  t.string :frequency, null: false  # hourly, daily, weekly, custom_interval
  t.jsonb :frequency_config, default: {}
  t.string :action, null: false  # create_draft, publish_article
  t.jsonb :action_config, default: {}
  t.text :additional_instructions
  t.datetime :last_run_at
  t.datetime :next_run_at, index: true
  t.string :state, default: "active", null: false  # active, running, failed
  t.string :service_name, null: false  # github_repo_recap
  t.boolean :enabled, default: true, null: false
  t.timestamps
end
```

## Frequency Configuration

### Hourly
Runs at a specific minute every hour.

```json
{
  "minute": 30  // 0-59
}
```

### Daily
Runs at a specific time every day.

```json
{
  "hour": 9,    // 0-23 (UTC)
  "minute": 0   // 0-59
}
```

### Weekly
Runs on a specific day of the week at a specific time.

```json
{
  "day_of_week": 5,  // 0-6 (0=Sunday, 6=Saturday)
  "hour": 9,          // 0-23 (UTC)
  "minute": 0         // 0-59
}
```

### Custom Interval
Runs every X days at a specific time.

```json
{
  "interval_days": 7,  // Number of days between runs
  "hour": 9,           // 0-23 (UTC)
  "minute": 0          // 0-59
}
```

## Supported AI Services

### GitHub Repo Recap
Generates a recap of GitHub repository activity.

**Service Name**: `github_repo_recap`

**Action Config**:
```json
{
  "repo_name": "forem/forem",  // Required: owner/repo format
  "days_ago": 7,                // Optional: Days of activity to include (default: 7)
  "tags": "opensource, github", // Optional: Comma-separated tags
  "subforem_id": 1              // Optional: Subforem to post in
}
```

## Actions

### Create Draft
Creates an unpublished article that requires manual review before publishing.

**Action**: `create_draft`

### Publish Article
Automatically publishes the generated article immediately.

**Action**: `publish_article`

## Usage

### Creating an Automation

1. Navigate to Admin → Customization → Subforems
2. Select a subforem → Community Bots
3. Click on a community bot
4. Click "Manage Automations"
5. Click "New Automation"
6. Configure the automation:
   - Select an AI Service (e.g., GitHub Repo Recap)
   - Choose an Action (Create Draft or Publish Article)
   - Set the Frequency
   - Configure service-specific settings
   - Add optional additional instructions

### Managing Automations

- **Enable/Disable**: Toggle automation on/off without deleting
- **Edit**: Modify configuration and schedule
- **Delete**: Permanently remove an automation

## Execution Flow

1. **Cron Job** (`ScheduledAutomations::ProcessWorker`) runs every 10 minutes
2. Worker finds automations with `next_run_at` in the past 10 minutes
3. For each due automation:
   - Mark as "running" to prevent concurrent execution
   - Call the configured AI service
   - Create/publish article with generated content
   - Calculate and set next run time
   - Mark as "active" (or "failed" if error occurred)

## State Management

- **active**: Ready to run when scheduled
- **running**: Currently executing (prevents concurrent runs)
- **failed**: Last execution failed (manual intervention may be needed)

## Prevention of Duplicate Runs

The system prevents duplicate executions through:
1. State checking (won't run if already "running")
2. 10-minute window check (only processes automations scheduled in last 10 minutes)
3. Atomic state transitions using database transactions

## Additional Instructions

The `additional_instructions` field allows customizing AI-generated content:

```
Focus on community contributions and highlight first-time contributors.
Include links to related documentation when mentioning new features.
Keep the tone casual and welcoming.
```

These instructions are appended to the AI service's prompt to guide content generation.

## API for New Services

To add a new AI service, implement:

1. Create a service class (e.g., `Ai::MyNewService`)
2. Service should return a result with `title` and `body` attributes (or nil if no content)
3. Add to `Executor#call_ai_service` case statement
4. Add UI configuration in admin views

Example service structure:
```ruby
module Ai
  class MyNewService
    Result = Struct.new(:title, :body, keyword_init: true)
    
    def initialize(config_params)
      @config = config_params
    end
    
    def generate
      # Return Result.new(title: "...", body: "...") or nil
    end
  end
end
```

## Monitoring

Check automation health:
```ruby
# Find failed automations
ScheduledAutomation.where(state: "failed")

# Find automations that haven't run recently
ScheduledAutomation.where("last_run_at < ?", 1.day.ago)

# Check next scheduled runs
ScheduledAutomation.enabled.order(:next_run_at).limit(10)
```

## Testing

Run the test suite:
```bash
bin/rspec spec/models/scheduled_automation_spec.rb
bin/rspec spec/services/scheduled_automations/
bin/rspec spec/workers/scheduled_automations/
bin/rspec spec/requests/admin/scheduled_automations_spec.rb
```

## Future Enhancements

Potential improvements:
- Support for more AI services (article summarization, community digests, etc.)
- Email notifications for failed automations
- Retry logic for transient failures
- Scheduling preview/dry-run mode
- Analytics dashboard for automation performance
- Support for user-specific GitHub credentials for private repos

