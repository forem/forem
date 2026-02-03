# Survey Resubmission Feature

## Overview

The survey system now supports allowing users to resubmit surveys after they have completed them. This is controlled by a new `allow_resubmission` field on the Survey model.

## Configuration

### Database Field

- **Field**: `allow_resubmission`
- **Type**: `boolean`
- **Default**: `false`
- **Null**: `false`

### Model Methods

The Survey model now includes two new methods:

#### `completed_by_user?(user)`
Returns `true` if the user has responded to all polls in the survey (either by voting, skipping, or providing text responses).

#### `can_user_submit?(user)`
Returns `true` if the user is allowed to submit the survey:
- Always returns `true` if `allow_resubmission` is `true`
- Returns `true` if the user hasn't completed the survey yet
- Returns `false` if the user has completed the survey and resubmission is not allowed

## Behavior

### When `allow_resubmission` is `false` (default)
- Users can only submit the survey once
- After completion, the survey shows a completion message
- Users cannot modify their responses

### When `allow_resubmission` is `true`
- Users can resubmit the survey multiple times
- Previous responses are cleared when the user returns to the survey
- Users can change their answers on subsequent submissions
- The survey behaves as if it's a fresh submission each time

## API Changes

### Surveys Controller (`/surveys/:id/votes`)

The response now includes additional fields:

```json
{
  "votes": { "poll_id": "response" },
  "can_submit": true,
  "completed": false,
  "allow_resubmission": false
}
```

- `can_submit`: Whether the user can currently submit the survey
- `completed`: Whether the user has completed all polls in the survey
- `allow_resubmission`: Whether the survey allows resubmission

### Poll Votes Controller

When a poll belongs to a survey, the controller now checks if the user can submit the survey before allowing votes.

### Poll Text Responses Controller

When a poll belongs to a survey, the controller now checks if the user can submit the survey before allowing text responses. Additionally, it now updates existing responses instead of creating duplicates.

## Frontend Changes

The JavaScript in `SurveyTag` has been updated to handle resubmission scenarios:

1. **Completed survey with resubmission allowed**: Clears all previous answers and allows fresh submission
2. **Completed survey with resubmission not allowed**: Shows completion message and prevents further interaction
3. **Incomplete survey**: Normal behavior

## Usage

To enable resubmission for a survey:

```ruby
survey = Survey.find(id)
survey.update!(allow_resubmission: true)
```

Or when creating a new survey:

```ruby
Survey.create!(
  title: "My Survey",
  allow_resubmission: true
)
```

## Testing

Comprehensive tests have been added for:
- Survey model methods
- Surveys controller
- Poll votes and text responses controllers
- End-to-end system behavior

Run the tests with:
```bash
bundle exec rspec spec/models/survey_spec.rb
bundle exec rspec spec/controllers/surveys_controller_spec.rb
bundle exec rspec spec/requests/poll_votes_spec.rb
bundle exec rspec spec/requests/poll_text_responses_spec.rb
```

