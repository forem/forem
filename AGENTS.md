# Forem Development Guidelines for Ona Agent

## Project Overview
Forem is a Ruby on Rails application with React/JavaScript frontend components. This is the codebase that powers DEV Community and other Forem instances.

## Common Commands

### Development Server
- `bin/rails server` - Start Rails development server
- `bin/dev` - Start development server with asset compilation (if available)
- `yarn storybook` - Start Storybook for component development

### Testing
- `bundle exec rspec` - Run Ruby/Rails tests
- `yarn test` - Run JavaScript tests with Jest
- `yarn test:watch` - Run JavaScript tests in watch mode
- `yarn e2e` - Run end-to-end tests with Cypress
- `bundle exec rspec spec/models/` - Run specific test directory
- `bundle exec rspec spec/path/to/file_spec.rb` - Run specific test file

### Code Quality & Linting
- `bundle exec rubocop` - Run Ruby linter
- `bundle exec rubocop -a` - Auto-fix Ruby linting issues
- `yarn lint:frontend` - Run JavaScript/JSX linter
- `bundle exec erblint --lint-all` - Lint ERB templates
- `yarn build` - Build frontend assets

### Database
- `bin/rails db:migrate` - Run database migrations
- `bin/rails db:rollback` - Rollback last migration
- `bin/rails db:reset` - Reset database (drop, create, migrate, seed)
- `bin/rails db:seed` - Seed database with sample data

## Key Directories

### Backend (Ruby/Rails)
- `app/models/` - ActiveRecord models and business logic
- `app/controllers/` - Rails controllers
- `app/services/` - Service objects for complex business logic
- `app/queries/` - Query objects for complex database queries
- `app/workers/` - Background job workers (Sidekiq)
- `app/views/` - ERB templates and partials
- `lib/` - Custom Ruby libraries and modules
- `spec/` - RSpec test files

### Frontend (JavaScript/React)
- `app/javascript/` - Modern JavaScript/React components
- `app/assets/javascripts/` - Legacy JavaScript files
- `app/assets/stylesheets/` - SCSS/CSS files
- `app/javascript/.storybook/` - Storybook configuration

### Configuration
- `config/` - Rails configuration files
- `db/migrate/` - Database migration files
- `.rubocop.yml` - Ruby linting configuration
- `.eslintrc.js` - JavaScript linting configuration

## Code Style & Conventions

### Ruby/Rails
- Follow the Ruby Style Guide and Rails conventions
- Use RuboCop for consistent formatting
- **IMPORTANT**: Always run `bundle exec rubocop` before committing Ruby code
- Service objects should be in `app/services/` and follow the pattern `ServiceName.new(params).call`
- Use strong parameters in controllers
- Write descriptive method and variable names

### JavaScript/React
- Use ESLint configuration defined in `.eslintrc.js`
- **IMPORTANT**: Always run `yarn lint:frontend` before committing frontend code
- Use functional components with hooks over class components
- Follow existing naming conventions for components and files

### Database
- **ALWAYS** create database migrations for schema changes
- Use descriptive migration names: `AddColumnToTable` or `CreateTableName`
- Include both `up` and `down` methods when needed
- **IMPORTANT**: Never edit existing migration files that have been committed

### Testing
- Write tests for all new features and bug fixes
- Use RSpec for Ruby/Rails tests with descriptive `describe` and `it` blocks
- Use Jest for JavaScript tests
- **IMPORTANT**: Maintain test coverage above 80%
- Test both happy path and edge cases

## Branch Naming & Git Workflow

### Branch Naming Pattern
Use this pattern for feature branches:
`[initials]/[feature-description]`

Examples:
- `jd/add-user-notifications`
- `sm/fix-article-rendering`
- `ak/improve-search-performance`

**IMPORTANT**: Always run `git config user.name` first to get your actual name for initials

### Commit Messages
- Use descriptive commit messages
- Start with a verb in present tense: "Add", "Fix", "Update", "Remove"
- Include context about what and why
- Reference issue numbers when applicable

Example:
```
Add user notification preferences

- Allow users to customize email notification settings
- Add new settings page with toggle controls
- Include database migration for notification preferences

Closes #1234
```

## Pull Request Guidelines
- Create small, focused PRs when possible
- Fill out the PR template completely
- Include tests for your changes
- Add screenshots for UI changes
- Ensure all CI checks pass
- **IMPORTANT**: Always include `Co-authored-by: Ona <no-reply@ona.com>` in commits made by Ona Agent

## Architecture Patterns

### Service Objects
Use service objects for complex business logic:
```ruby
class ArticlePublisher
  def initialize(article, user)
    @article = article
    @user = user
  end

  def call
    return false unless can_publish?
    
    @article.update!(published: true, published_at: Time.current)
    notify_followers
    true
  end

  private

  def can_publish?
    @user.can_publish?(@article)
  end

  def notify_followers
    # Notification logic
  end
end
```

### Query Objects
Use query objects for complex database queries:
```ruby
class PopularArticlesQuery
  def initialize(timeframe: 1.week.ago)
    @timeframe = timeframe
  end

  def call
    Article.published
           .where(published_at: @timeframe..)
           .joins(:reactions)
           .group('articles.id')
           .order('COUNT(reactions.id) DESC')
  end
end
```

## Performance Considerations
- Use database indexes for frequently queried columns
- Avoid N+1 queries with `includes`, `joins`, or `preload`
- Use background jobs for time-consuming operations
- Cache expensive operations when appropriate
- **IMPORTANT**: Always check query performance with `EXPLAIN` for complex queries

## Security Guidelines
- Use strong parameters in controllers
- Sanitize user input in views with appropriate helpers
- Use HTTPS for all external API calls
- Never commit secrets or API keys
- **IMPORTANT**: Always use parameterized queries to prevent SQL injection

## Common Gotchas
- Strong migrations gem may prevent certain migration operations
- Use `safety_assured` block for migrations that are safe but flagged
- Frontend assets need to be built with `yarn build` for production
- Some tests may require specific database setup or factories
- **IMPORTANT**: Always test database migrations in both directions (up and down)

## Getting Help
- Check existing documentation in `docs/` directory
- Look for similar patterns in the codebase
- Run `bin/rails routes` to see available routes
- Use `bin/rails console` for debugging and exploration
- Check the GitHub issues for known problems or feature requests

## Quality Checklist
Before submitting any changes:
- [ ] Tests pass (`bundle exec rspec` and `yarn test`)
- [ ] Linting passes (`bundle exec rubocop` and `yarn lint:frontend`)
- [ ] Database migrations run successfully
- [ ] No new security vulnerabilities introduced
- [ ] Performance impact considered
- [ ] Documentation updated if needed