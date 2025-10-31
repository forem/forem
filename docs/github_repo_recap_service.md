# GitHub Repository Recap Service

## Overview

The `Ai::GithubRepoRecap` service generates AI-powered summaries of GitHub repository activity over a specified timeframe. It fetches pull requests and commits from a repository and creates a markdown-formatted recap that highlights significant changes while aggregating minor updates.

## Purpose

This service is useful for:
- Creating weekly/monthly development digests
- Generating changelog summaries
- Producing content for newsletters or community updates
- Tracking project progress over time
- Creating shareable recaps of repository activity

## Features

- **Intelligent Summarization**: Uses AI to identify and highlight important changes
- **Smart Aggregation**: Groups minor changes (typos, small fixes) together
- **Embedded Links**: Generates `{% embed %}` tags for important pull requests
- **Activity Detection**: Returns `nil` when there's no activity to report
- **Flexible Timeframes**: Supports any custom time period
- **Error Handling**: Gracefully handles GitHub API errors and AI failures

## Usage

### Basic Usage

```ruby
# Generate a weekly recap
recap_service = Ai::GithubRepoRecap.new("forem/forem", days_ago: 7)
result = recap_service.generate

if result
  puts result.title
  puts result.body
else
  puts "No activity in this timeframe"
end
```

### Custom Timeframes

```ruby
# Monthly recap
monthly = Ai::GithubRepoRecap.new("rails/rails", days_ago: 30)
result = monthly.generate

# Two-week recap
biweekly = Ai::GithubRepoRecap.new("user/repo", days_ago: 14)
result = biweekly.generate
```

### With Authenticated User

```ruby
# Use an authenticated GitHub client to access private repositories
user = User.find_by(github_username: "username")
client = Github::OauthClient.for_user(user)

recap = Ai::GithubRepoRecap.new(
  "organization/private-repo",
  days_ago: 7,
  github_client: client
)

result = recap.generate
```

### Dependency Injection for Testing

```ruby
# Inject custom clients for testing
mock_github = double("GithubClient")
mock_ai = double("AiClient")

recap = Ai::GithubRepoRecap.new(
  "test/repo",
  days_ago: 7,
  github_client: mock_github,
  ai_client: mock_ai
)
```

## Return Value

The service returns either:
- `nil` if there's no activity
- `Ai::GithubRepoRecap::RecapResult` struct with:
  - `title` (String): A compelling title for the recap
  - `body` (String): Markdown-formatted body with embedded PR links

### Example Result

```ruby
result = recap.generate

result.title
# => "Weekly Recap: Major Performance Improvements and New Features"

result.body
# => "This week saw significant progress on the Forem repository!
#
#     ## Major Changes
#
#     {% embed https://github.com/forem/forem/pull/12345 %}
#
#     The team shipped a complete rewrite of the notification system...
#
#     ## Minor Updates
#
#     - 15 bug fixes across various components
#     - Documentation improvements
#     - Dependency updates"
```

## Configuration

The service requires the following environment variables:
- `GEMINI_API_KEY`: API key for Google Gemini AI (required)
- `GEMINI_API_MODEL`: Model to use (optional, defaults to "gemini-2.5-pro")

For GitHub access:
- **Public repositories**: No authentication needed (uses app credentials)
- **Private repositories**: Requires user authentication via `Github::OauthClient.for_user(user)`

## How It Works

1. **Fetch Activity**: Retrieves merged pull requests and commits from GitHub
2. **Filter by Timeframe**: Only includes activity within the specified period
3. **Check for Activity**: Returns `nil` if no activity found
4. **Build Context**: Constructs a detailed prompt with PR and commit information
5. **AI Generation**: Sends the prompt to Google Gemini for summary generation
6. **Parse Response**: Extracts title and body from AI response
7. **Return Result**: Returns structured result with title and markdown body

## Prompt Engineering

The service instructs the AI to:
- Focus on significant changes (features, breaking changes, performance improvements)
- Aggregate minor changes into categories
- Use `{% embed URL %}` syntax for important PRs (typically 3-7 embeds)
- Keep the tone professional but engaging
- Create a compelling title under 100 characters

## Error Handling

The service handles various error scenarios:

### GitHub API Errors
- **NotFound**: Repository doesn't exist or is inaccessible
- **Unauthorized**: Invalid or expired authentication
- **Rate Limiting**: GitHub API rate limits exceeded

### AI Errors
- **API Failures**: Gemini API connection or processing errors
- **Malformed Responses**: Falls back to extracting what it can

All errors are logged and the service returns `nil` gracefully.

## Performance Considerations

### Token Limits
- Commits are limited to the first 50 in the prompt to avoid AI token limits
- Commit fetching is capped at 300 total commits to prevent excessive API calls
- For repositories with high activity, consider shorter timeframes

### API Rate Limits
- GitHub API has rate limits (5,000/hour for authenticated, 60/hour for unauthenticated)
- Service uses smart pagination to minimize API calls:
  - Fetches PRs in pages of 100
  - Stops when encountering PRs before the timeframe
  - Maximum of 5 pages (500 PRs) to prevent hanging on repos with long histories
  - Commits limited to 300 maximum across all pages
- Consider caching results for frequently accessed recaps

### Response Time
- Typical generation time: 3-10 seconds
- Factors: Number of PRs/commits, AI model speed, network latency
- Optimized pagination prevents hanging on repositories with thousands of PRs

## Integration Examples

### Scheduled Weekly Digest

```ruby
# In a Sidekiq worker or scheduled task
class WeeklyRepoDigestWorker
  include Sidekiq::Job

  def perform(repo_name)
    recap = Ai::GithubRepoRecap.new(repo_name, days_ago: 7)
    result = recap.generate

    return unless result

    # Create an article or send via email
    Article.create!(
      title: result.title,
      body_markdown: result.body,
      user: User.admin.first
    )
  end
end
```

### API Endpoint

```ruby
# In a controller
class Api::GithubRecapsController < ApplicationController
  def show
    recap = Ai::GithubRepoRecap.new(
      params[:repo],
      days_ago: params[:days]&.to_i || 7
    )
    
    result = recap.generate

    if result
      render json: {
        title: result.title,
        body: result.body
      }
    else
      render json: { message: "No activity found" }, status: :not_found
    end
  end
end
```

## Testing

The service is fully tested with RSpec. See `spec/services/ai/github_repo_recap_spec.rb` for comprehensive test coverage including:
- Basic recap generation
- Empty activity handling
- Error scenarios
- Different timeframes
- Custom clients

## Limitations

1. **Public Data Only** (without authentication): Can only access public repositories
2. **Recent Activity**: GitHub API limits historical data access
3. **Token Limits**: Very large repositories may hit AI token limits
4. **Rate Limits**: Subject to both GitHub and Gemini API rate limits
5. **Language**: AI responses are in English by default

## Future Enhancements

Potential improvements:
- Support for filtering by file paths or directories
- Language customization for AI responses
- Custom prompt templates
- Caching layer for frequently requested recaps
- Webhook integration for real-time recaps
- Support for other code hosting platforms (GitLab, Bitbucket)

## Related Services

- `Ai::Base` - Base AI client for Gemini API
- `Github::OauthClient` - GitHub API client wrapper
- Other AI services in `app/services/ai/`

## Support

For issues or questions:
1. Check the test suite for usage examples
2. Review the inline documentation in the service file
3. Consult the Gemini API documentation for AI-related issues
4. Consult the Octokit documentation for GitHub API issues

