# Development Workflow Guide

This guide outlines the recommended development workflow for contributing to Forem, optimized for both human developers and Ona Agent.

## Quick Start Checklist

### Before Starting Development
- [ ] Pull latest changes from main: `git pull origin main`
- [ ] Create feature branch: `git checkout -b [initials]/[feature-name]`
- [ ] Install dependencies: `bundle install && yarn install`
- [ ] Set up database: `bin/rails db:migrate`
- [ ] Start development server: `bin/rails server`

### Before Committing
- [ ] Run tests: `bundle exec rspec && yarn test`
- [ ] Run linters: `bundle exec rubocop && yarn lint:frontend`
- [ ] Check for security issues: `bundle audit`
- [ ] Review your changes: `git diff`
- [ ] Write descriptive commit message

### Before Creating PR
- [ ] Rebase on latest main: `git rebase main`
- [ ] Push branch: `git push origin [branch-name]`
- [ ] Fill out PR template completely
- [ ] Request appropriate reviewers

## Detailed Workflow

### 1. Setting Up Your Development Environment

#### Initial Setup
```bash
# Clone the repository (if not already done)
git clone https://github.com/forem/forem.git
cd forem

# Install Ruby dependencies
bundle install

# Install Node.js dependencies
yarn install

# Set up the database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

# Start the development server
bin/rails server
```

#### Environment Variables
Copy `.env_sample` to `.env` and configure as needed:
```bash
cp .env_sample .env
# Edit .env with your local configuration
```

### 2. Feature Development Process

#### Step 1: Create Feature Branch
```bash
# Get your initials from git config
git config user.name

# Create and switch to feature branch
git checkout -b jd/add-user-notifications

# Alternative: checkout from specific commit
git checkout -b jd/fix-article-bug main
```

#### Step 2: Development Cycle
```bash
# Make your changes
# Edit files...

# Run tests frequently during development
bundle exec rspec spec/models/user_spec.rb
yarn test src/components/Article.test.jsx

# Run linters to catch issues early
bundle exec rubocop app/models/user.rb
yarn lint:frontend

# Check database changes
bin/rails db:migrate:status
```

#### Step 3: Commit Your Changes
```bash
# Stage your changes
git add .

# Or stage specific files
git add app/models/user.rb spec/models/user_spec.rb

# Commit with descriptive message
git commit -m "Add user notification preferences

- Allow users to customize email notification settings
- Add database migration for notification_preferences column
- Include validation and default values
- Add comprehensive test coverage

Co-authored-by: Ona <no-reply@ona.com>"
```

### 3. Testing Strategy

#### Running Tests

##### Ruby/Rails Tests (RSpec)
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run specific test
bundle exec rspec spec/models/user_spec.rb:25

# Run tests with coverage
COVERAGE=true bundle exec rspec

# Run tests matching a pattern
bundle exec rspec --tag focus
```

##### JavaScript Tests (Jest)
```bash
# Run all JavaScript tests
yarn test

# Run tests in watch mode
yarn test:watch

# Run specific test file
yarn test src/components/Article.test.jsx

# Run tests with coverage
yarn test --coverage
```

##### End-to-End Tests (Cypress)
```bash
# Run E2E tests
yarn e2e

# Run specific E2E test
yarn e2e --spec "cypress/e2e/articles.cy.js"
```

#### Writing Tests

##### Model Tests (RSpec)
```ruby
# spec/models/article_spec.rb
RSpec.describe Article, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(255) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:comments) }
  end

  describe '#published?' do
    context 'when published_at is set' do
      let(:article) { create(:article, published_at: 1.hour.ago) }
      
      it 'returns true' do
        expect(article.published?).to be true
      end
    end
  end
end
```

##### Component Tests (Jest)
```javascript
// src/components/__tests__/Article.test.jsx
import { render, screen } from '@testing-library/react';
import Article from '../Article';

describe('Article', () => {
  const mockArticle = {
    id: 1,
    title: 'Test Article',
    body: 'Test content',
    published: true
  };

  it('renders article title', () => {
    render(<Article article={mockArticle} />);
    expect(screen.getByText('Test Article')).toBeInTheDocument();
  });

  it('shows published status when article is published', () => {
    render(<Article article={mockArticle} />);
    expect(screen.getByText(/published/i)).toBeInTheDocument();
  });
});
```

### 4. Database Migrations

#### Creating Migrations
```bash
# Generate migration
bin/rails generate migration AddNotificationPreferencesToUsers notification_preferences:text

# Generate model with migration
bin/rails generate model UserPreference user:references setting_name:string value:text

# Generate migration for adding index
bin/rails generate migration AddIndexToArticlesPublishedAt
```

#### Migration Best Practices
```ruby
class AddNotificationPreferencesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :notification_preferences, :text, default: '{}', null: false
    add_index :users, :notification_preferences, using: :gin
  end
end
```

#### Running Migrations
```bash
# Run pending migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Rollback specific number of migrations
bin/rails db:rollback STEP=3

# Run specific migration
bin/rails db:migrate:up VERSION=20231201120000

# Check migration status
bin/rails db:migrate:status
```

### 5. Code Quality Checks

#### Automated Linting
```bash
# Ruby linting
bundle exec rubocop

# Auto-fix Ruby issues
bundle exec rubocop -a

# JavaScript linting
yarn lint:frontend

# ERB template linting
bundle exec erblint --lint-all
```

#### Security Checks
```bash
# Check for vulnerable gems
bundle audit

# Check for security issues in JavaScript packages
yarn audit

# Run Brakeman for Rails security scanning
bundle exec brakeman
```

#### Performance Checks
```bash
# Check for N+1 queries in tests
BULLET=true bundle exec rspec

# Analyze bundle size
yarn build --analyze
```

### 6. Pull Request Process

#### Before Creating PR
```bash
# Ensure you're on your feature branch
git branch

# Rebase on latest main
git checkout main
git pull origin main
git checkout your-feature-branch
git rebase main

# Run full test suite
bundle exec rspec
yarn test

# Push your branch
git push origin your-feature-branch
```

#### Creating the PR
1. Go to GitHub and create a new pull request
2. Fill out the PR template completely:
   - Select PR type (Feature, Bug Fix, etc.)
   - Provide clear description
   - Link related issues
   - Add QA instructions
   - Include screenshots for UI changes
   - Check accessibility requirements
   - Confirm tests are added

#### PR Review Process
1. **Automated Checks**: Ensure all CI checks pass
2. **Code Review**: Address reviewer feedback promptly
3. **Testing**: Verify QA instructions work as expected
4. **Approval**: Get required approvals from maintainers
5. **Merge**: Maintainer will merge when ready

### 7. Common Development Tasks

#### Adding a New Feature
```bash
# 1. Create feature branch
git checkout -b jd/user-bookmarks

# 2. Generate necessary files
bin/rails generate model Bookmark user:references article:references
bin/rails generate controller Bookmarks

# 3. Run migration
bin/rails db:migrate

# 4. Write tests
# Create spec files...

# 5. Implement feature
# Edit model, controller, views...

# 6. Test your changes
bundle exec rspec spec/models/bookmark_spec.rb
bundle exec rspec spec/controllers/bookmarks_controller_spec.rb

# 7. Commit and push
git add .
git commit -m "Add user bookmarking feature"
git push origin jd/user-bookmarks
```

#### Fixing a Bug
```bash
# 1. Create bug fix branch
git checkout -b jd/fix-article-rendering

# 2. Write failing test first (TDD)
# Add test that reproduces the bug

# 3. Run test to confirm it fails
bundle exec rspec spec/models/article_spec.rb:42

# 4. Fix the bug
# Edit the relevant files

# 5. Run test to confirm fix
bundle exec rspec spec/models/article_spec.rb:42

# 6. Run full test suite
bundle exec rspec

# 7. Commit and push
git add .
git commit -m "Fix article rendering issue with special characters"
git push origin jd/fix-article-rendering
```

#### Refactoring Code
```bash
# 1. Create refactoring branch
git checkout -b jd/refactor-user-service

# 2. Ensure existing tests pass
bundle exec rspec spec/services/user_service_spec.rb

# 3. Refactor code while keeping tests green
# Make incremental changes

# 4. Run tests after each change
bundle exec rspec spec/services/user_service_spec.rb

# 5. Add new tests if needed
# Test new methods or edge cases

# 6. Final test run
bundle exec rspec

# 7. Commit and push
git add .
git commit -m "Refactor UserService for better maintainability"
git push origin jd/refactor-user-service
```

### 8. Troubleshooting Common Issues

#### Database Issues
```bash
# Reset database if corrupted
bin/rails db:drop db:create db:migrate db:seed

# Fix migration conflicts
bin/rails db:migrate:status
# Manually resolve conflicts in schema.rb

# Check for pending migrations
bin/rails db:abort_if_pending_migrations
```

#### Test Issues
```bash
# Clear test database
RAILS_ENV=test bin/rails db:drop db:create db:migrate

# Fix flaky tests
bundle exec rspec --seed 12345  # Use specific seed

# Debug failing tests
bundle exec rspec --format documentation
```

#### Asset Issues
```bash
# Rebuild assets
yarn build

# Clear asset cache
bin/rails assets:clobber

# Check for JavaScript errors
yarn lint:frontend
```

### 9. Best Practices Summary

#### Git Workflow
- Keep branches focused and short-lived
- Use descriptive branch names and commit messages
- Rebase instead of merge to keep history clean
- Push frequently to avoid losing work

#### Code Quality
- Write tests before or alongside code
- Run linters frequently during development
- Keep methods and classes small and focused
- Use meaningful variable and method names

#### Collaboration
- Communicate early about large changes
- Ask for help when stuck
- Review others' code thoughtfully
- Keep PRs small and reviewable

#### Performance
- Consider database query performance
- Use background jobs for expensive operations
- Monitor application performance metrics
- Optimize frontend bundle size

---

This workflow ensures consistent, high-quality contributions to the Forem codebase while maintaining a smooth development experience for all contributors.