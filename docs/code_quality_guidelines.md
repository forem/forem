# Code Quality Guidelines for Forem

This document outlines code quality standards and best practices for the Forem codebase.

## Overview

Maintaining high code quality is essential for:
- Reducing bugs and security vulnerabilities
- Improving maintainability and readability
- Ensuring consistent development experience
- Facilitating code reviews and collaboration

## Automated Quality Checks

### Ruby/Rails Code Quality

#### RuboCop Configuration
- Configuration: `.rubocop.yml` and `.rubocop_todo.yml`
- Run: `bundle exec rubocop`
- Auto-fix: `bundle exec rubocop -a`
- **Required**: All Ruby code must pass RuboCop checks before merging

#### Key RuboCop Rules
- **Line Length**: Maximum 120 characters
- **Method Length**: Keep methods under 15 lines when possible
- **Class Length**: Keep classes focused and under 100 lines
- **Complexity**: Avoid deeply nested conditionals (max 3 levels)

### JavaScript/Frontend Code Quality

#### ESLint Configuration
- Configuration: `.eslintrc.js`
- Run: `yarn lint:frontend`
- **Required**: All JavaScript/JSX code must pass ESLint checks

#### Key ESLint Rules
- Use consistent indentation (2 spaces)
- Prefer `const` and `let` over `var`
- Use semicolons consistently
- Avoid unused variables and imports

### ERB Template Quality
- Configuration: `.erb-lint.yml`
- Run: `bundle exec erblint --lint-all`
- Focus on accessibility and semantic HTML

## Code Review Standards

### What to Look For

#### Functionality
- [ ] Code does what it's supposed to do
- [ ] Edge cases are handled appropriately
- [ ] Error handling is implemented
- [ ] No obvious bugs or logical errors

#### Security
- [ ] User input is properly sanitized
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (proper escaping)
- [ ] Authentication and authorization checks
- [ ] No secrets or sensitive data in code

#### Performance
- [ ] No N+1 query problems
- [ ] Appropriate database indexes
- [ ] Efficient algorithms and data structures
- [ ] Proper use of caching where beneficial
- [ ] Background jobs for expensive operations

#### Maintainability
- [ ] Code is readable and well-organized
- [ ] Appropriate comments for complex logic
- [ ] Consistent naming conventions
- [ ] Single Responsibility Principle followed
- [ ] DRY (Don't Repeat Yourself) principle applied

#### Testing
- [ ] Adequate test coverage (aim for 80%+)
- [ ] Tests cover both happy path and edge cases
- [ ] Tests are readable and maintainable
- [ ] No flaky or unreliable tests

## Testing Standards

### Ruby/Rails Testing (RSpec)

#### Test Structure
```ruby
RSpec.describe ArticleService do
  describe '#publish' do
    context 'when article is valid' do
      it 'publishes the article successfully' do
        # Arrange
        article = create(:article, :draft)
        
        # Act
        result = described_class.new(article).publish
        
        # Assert
        expect(result).to be_truthy
        expect(article.reload).to be_published
      end
    end

    context 'when article is invalid' do
      it 'returns false and does not publish' do
        # Test implementation
      end
    end
  end
end
```

#### Testing Best Practices
- Use descriptive test names that explain the scenario
- Follow Arrange-Act-Assert pattern
- Use factories instead of fixtures
- Test behavior, not implementation
- Keep tests independent and isolated

### JavaScript Testing (Jest)

#### Test Structure
```javascript
describe('ArticleComponent', () => {
  describe('when article is published', () => {
    it('displays the published date', () => {
      // Arrange
      const article = { published: true, publishedAt: '2023-01-01' };
      
      // Act
      render(<ArticleComponent article={article} />);
      
      // Assert
      expect(screen.getByText('Published on Jan 1, 2023')).toBeInTheDocument();
    });
  });
});
```

## Database Standards

### Migration Quality

#### Migration Checklist
- [ ] Migration is reversible (has proper `down` method)
- [ ] Migration name is descriptive
- [ ] No data loss in production
- [ ] Proper indexes added for new columns that will be queried
- [ ] Foreign key constraints where appropriate

#### Example Migration
```ruby
class AddPublishedAtToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :published_at, :datetime
    add_index :articles, :published_at
  end
end
```

### Query Performance

#### N+1 Query Prevention
```ruby
# Bad - N+1 query
articles = Article.published
articles.each { |article| puts article.user.name }

# Good - Eager loading
articles = Article.published.includes(:user)
articles.each { |article| puts article.user.name }
```

#### Complex Query Organization
```ruby
# Use query objects for complex queries
class PopularArticlesQuery
  def initialize(timeframe: 1.week.ago)
    @timeframe = timeframe
  end

  def call
    Article.published
           .where(published_at: @timeframe..)
           .joins(:reactions)
           .group('articles.id')
           .having('COUNT(reactions.id) > ?', 5)
           .order('COUNT(reactions.id) DESC')
  end
end
```

## Performance Guidelines

### Backend Performance

#### Service Objects
- Keep service objects focused on a single responsibility
- Use dependency injection for testability
- Return consistent result objects

```ruby
class ArticlePublisher
  def initialize(article, user)
    @article = article
    @user = user
  end

  def call
    return Result.failure('Unauthorized') unless authorized?
    return Result.failure('Invalid article') unless valid?

    publish_article
    Result.success(@article)
  end

  private

  def authorized?
    @user.can_publish?(@article)
  end

  def valid?
    @article.valid?
  end

  def publish_article
    @article.update!(published: true, published_at: Time.current)
    NotificationWorker.perform_async(@article.id)
  end
end
```

#### Background Jobs
- Use background jobs for expensive operations
- Keep job payloads small (pass IDs, not objects)
- Make jobs idempotent when possible

### Frontend Performance

#### Component Optimization
- Use React.memo for expensive components
- Implement proper key props for lists
- Avoid inline functions in render methods
- Use lazy loading for large components

#### Bundle Size Management
- Import only what you need from libraries
- Use dynamic imports for code splitting
- Monitor bundle size in CI/CD

## Security Standards

### Input Validation
```ruby
# Controller strong parameters
def article_params
  params.require(:article).permit(:title, :body, :published, tag_list: [])
end

# Model validation
class Article < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :body, presence: true
  validates :user_id, presence: true
end
```

### Output Escaping
```erb
<!-- Automatic escaping (safe) -->
<%= article.title %>

<!-- Raw HTML (use with caution) -->
<%== sanitized_html(article.body) %>

<!-- Never do this with user input -->
<%== article.body %> <!-- DANGEROUS -->
```

### Authentication & Authorization
```ruby
# Controller authorization
before_action :authenticate_user!
before_action :authorize_article_access!, only: [:show, :edit, :update]

private

def authorize_article_access!
  redirect_to root_path unless current_user.can_access?(@article)
end
```

## Documentation Standards

### Code Comments
- Comment the "why", not the "what"
- Use comments for complex business logic
- Keep comments up to date with code changes

```ruby
# Good - explains business logic
def calculate_reading_time
  # Average reading speed is 200 words per minute
  # Add extra time for code blocks which are read slower
  word_count = body.split.length
  code_blocks = body.scan(/```/).length / 2
  
  base_time = (word_count / 200.0).ceil
  code_penalty = code_blocks * 0.5
  
  [base_time + code_penalty, 1].max
end

# Bad - explains obvious code
def set_published_at
  # Set published_at to current time
  self.published_at = Time.current
end
```

### API Documentation
- Document public API methods
- Include parameter types and return values
- Provide usage examples

```ruby
# Publishes an article and notifies followers
#
# @param article [Article] the article to publish
# @param notify [Boolean] whether to send notifications (default: true)
# @return [Boolean] true if successful, false otherwise
#
# @example
#   publisher = ArticlePublisher.new(article, user)
#   publisher.call(notify: false)
def call(notify: true)
  # Implementation
end
```

## Continuous Improvement

### Metrics to Track
- Test coverage percentage
- Code complexity scores
- Performance benchmarks
- Security vulnerability counts
- Code review turnaround time

### Regular Reviews
- Weekly code quality discussions
- Monthly refactoring sessions
- Quarterly architecture reviews
- Annual security audits

### Tools Integration
- Pre-commit hooks for linting
- CI/CD pipeline quality gates
- Automated security scanning
- Performance monitoring

## Resources

### Internal Documentation
- [AGENTS.md](../AGENTS.md) - Development guidelines for Ona Agent
- [Development Workflow Guide](development_workflow.md)
- [Testing Best Practices](testing_best_practices.md)

### External Resources
- [Ruby Style Guide](https://rubystyle.guide/)
- [Rails Best Practices](https://rails-bestpractices.com/)
- [JavaScript Standard Style](https://standardjs.com/)
- [React Best Practices](https://react.dev/learn/thinking-in-react)

---

Remember: Code quality is everyone's responsibility. When in doubt, ask for a second opinion during code review!