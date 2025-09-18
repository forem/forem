# Testing and Linting Quick Reference

This document provides a comprehensive reference for all testing and linting commands used in the Forem project.

## Testing Commands

### Ruby/Rails Testing (RSpec)

#### Basic Commands
```bash
# Run all tests
bundle exec rspec

# Run all tests with coverage
COVERAGE=true bundle exec rspec

# Run tests in parallel (faster)
bundle exec rspec --parallel

# Run tests with detailed output
bundle exec rspec --format documentation
```

#### Specific Test Execution
```bash
# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run specific test by line number
bundle exec rspec spec/models/user_spec.rb:25

# Run specific test by description
bundle exec rspec spec/models/user_spec.rb -e "validates presence of email"

# Run tests matching a pattern
bundle exec rspec --grep "validation"
```

#### Test Categories
```bash
# Run only model tests
bundle exec rspec spec/models/

# Run only controller tests
bundle exec rspec spec/controllers/

# Run only request tests
bundle exec rspec spec/requests/

# Run only service tests
bundle exec rspec spec/services/

# Run only system tests (integration)
bundle exec rspec spec/system/
```

#### Test Tags and Filtering
```bash
# Run tests with specific tag
bundle exec rspec --tag focus

# Skip tests with specific tag
bundle exec rspec --tag ~slow

# Run tests with multiple tags
bundle exec rspec --tag "focus and unit"

# Run failed tests from last run
bundle exec rspec --only-failures

# Run next failure (after fixing one)
bundle exec rspec --next-failure
```

#### Debugging Tests
```bash
# Run with specific seed for reproducibility
bundle exec rspec --seed 12345

# Run with backtrace for debugging
bundle exec rspec --backtrace

# Run with warnings enabled
bundle exec rspec --warnings

# Profile slow tests
bundle exec rspec --profile 10
```

### JavaScript Testing (Jest)

#### Basic Commands
```bash
# Run all JavaScript tests
yarn test

# Run tests in watch mode (re-runs on file changes)
yarn test:watch

# Run tests with coverage report
yarn test --coverage

# Run tests in CI mode (no watch, single run)
yarn test --ci
```

#### Specific Test Execution
```bash
# Run specific test file
yarn test src/components/Article.test.jsx

# Run tests matching a pattern
yarn test --testNamePattern="should render"

# Run tests in specific directory
yarn test src/components/

# Run tests for changed files only
yarn test --onlyChanged
```

#### Debugging JavaScript Tests
```bash
# Run tests with verbose output
yarn test --verbose

# Run tests with debug information
yarn test --debug

# Update snapshots
yarn test --updateSnapshot

# Run tests without cache
yarn test --no-cache
```

### End-to-End Testing (Cypress)

#### Basic Commands
```bash
# Run all E2E tests headlessly
yarn e2e

# Run E2E tests with GUI
yarn cypress open

# Run specific test file
yarn e2e --spec "cypress/e2e/articles.cy.js"

# Run tests with specific browser
yarn e2e --browser chrome
```

#### Cypress-Specific Options
```bash
# Run with creator onboarding seed data
yarn e2e:creator-onboarding-seed

# Run tests with video recording
yarn e2e --record

# Run tests in specific environment
yarn e2e --env environment=staging
```

## Linting Commands

### Ruby Linting (RuboCop)

#### Basic Commands
```bash
# Run RuboCop on all files
bundle exec rubocop

# Auto-fix issues where possible
bundle exec rubocop -a

# Auto-fix unsafe issues (use with caution)
bundle exec rubocop -A

# Show only offenses (no summary)
bundle exec rubocop --format offenses
```

#### Specific File/Directory Linting
```bash
# Lint specific file
bundle exec rubocop app/models/user.rb

# Lint specific directory
bundle exec rubocop app/models/

# Lint changed files only
bundle exec rubocop $(git diff --name-only --diff-filter=AM main | grep '\.rb$')
```

#### RuboCop Configuration and Reporting
```bash
# Show configuration for specific file
bundle exec rubocop --show-config app/models/user.rb

# Generate TODO file for existing offenses
bundle exec rubocop --auto-gen-config

# Show cops (rules) information
bundle exec rubocop --show-cops

# Run with specific format
bundle exec rubocop --format json
bundle exec rubocop --format html -o rubocop-report.html
```

#### RuboCop Cop Management
```bash
# Run only specific cop
bundle exec rubocop --only Style/StringLiterals

# Exclude specific cop
bundle exec rubocop --except Style/Documentation

# List all available cops
bundle exec rubocop --show-cops | grep "^[A-Z]"
```

### JavaScript/JSX Linting (ESLint)

#### Basic Commands
```bash
# Run ESLint on all frontend files
yarn lint:frontend

# Auto-fix ESLint issues
yarn lint:frontend --fix

# Run ESLint with specific format
yarn lint:frontend --format table
```

#### Specific File/Directory Linting
```bash
# Lint specific file
npx eslint app/javascript/components/Article.jsx

# Lint specific directory
npx eslint app/javascript/components/

# Lint with specific configuration
npx eslint --config .eslintrc.js app/javascript/
```

#### ESLint Debugging
```bash
# Show configuration for file
npx eslint --print-config app/javascript/components/Article.jsx

# Debug ESLint rules
npx eslint --debug app/javascript/components/Article.jsx

# Show ignored files
npx eslint --print-config . | grep -A 20 ignorePatterns
```

### ERB Template Linting

#### Basic Commands
```bash
# Lint all ERB templates
bundle exec erblint --lint-all

# Auto-correct ERB issues
bundle exec erblint --lint-all --autocorrect

# Lint specific file
bundle exec erblint app/views/articles/show.html.erb
```

#### ERB Linting Options
```bash
# Lint with specific format
bundle exec erblint --lint-all --format compact

# Show configuration
bundle exec erblint --show-linters

# Lint changed files only
bundle exec erblint $(git diff --name-only --diff-filter=AM main | grep '\.erb$')
```

## Security and Quality Checks

### Security Auditing

#### Ruby Security (Bundler Audit)
```bash
# Check for vulnerable gems
bundle audit

# Update vulnerability database and check
bundle audit --update

# Check specific Gemfile
bundle audit --gemfile-lock Gemfile.lock
```

#### JavaScript Security
```bash
# Check for vulnerable npm packages
yarn audit

# Fix vulnerabilities automatically
yarn audit --fix

# Check with specific severity
yarn audit --level moderate
```

#### Rails Security (Brakeman)
```bash
# Run Brakeman security scanner
bundle exec brakeman

# Run with specific output format
bundle exec brakeman -f json -o brakeman-report.json

# Run with specific confidence level
bundle exec brakeman --confidence-level 2

# Skip certain checks
bundle exec brakeman --skip-checks CheckDefaultRoutes
```

### Code Quality Analysis

#### Ruby Code Quality
```bash
# Check code complexity with Flog
bundle exec flog app/models/

# Check code duplication with Flay
bundle exec flay app/models/

# Check method complexity with Reek
bundle exec reek app/models/
```

#### Database Query Analysis
```bash
# Check for N+1 queries in tests
BULLET=true bundle exec rspec

# Run with Bullet in development
BULLET=true bin/rails server
```

## Performance Testing

### Load Testing
```bash
# Run performance tests (if available)
bundle exec rspec spec/performance/

# Profile memory usage
RUBY_PROF=true bundle exec rspec spec/models/user_spec.rb
```

### Frontend Performance
```bash
# Analyze bundle size
yarn build --analyze

# Check for unused dependencies
npx depcheck

# Audit bundle for duplicates
npx webpack-bundle-analyzer public/packs/manifest.json
```

## Continuous Integration Commands

### Pre-commit Hooks
```bash
# Run all pre-commit checks
yarn prepare

# Run lint-staged (staged files only)
npx lint-staged

# Skip pre-commit hooks (use sparingly)
git commit --no-verify
```

### Full CI Pipeline Simulation
```bash
# Run complete test suite (mimics CI)
bundle exec rspec && yarn test && yarn lint:frontend && bundle exec rubocop

# Run with coverage reports
COVERAGE=true bundle exec rspec && yarn test --coverage

# Run security checks
bundle audit && yarn audit && bundle exec brakeman
```

## Useful Aliases and Scripts

### Bash Aliases (add to ~/.bashrc or ~/.zshrc)
```bash
# Testing aliases
alias rspec='bundle exec rspec'
alias rubocop='bundle exec rubocop'
alias rubocop-fix='bundle exec rubocop -a'

# Quick test commands
alias test-models='bundle exec rspec spec/models/'
alias test-controllers='bundle exec rspec spec/controllers/'
alias test-js='yarn test'
alias lint-all='bundle exec rubocop && yarn lint:frontend'

# Git + test workflow
alias git-test='git add . && bundle exec rspec && yarn test && git commit'
```

### Custom Scripts
Create a `scripts/quality-check.sh` file:
```bash
#!/bin/bash
echo "Running quality checks..."

echo "1. Ruby linting..."
bundle exec rubocop || exit 1

echo "2. JavaScript linting..."
yarn lint:frontend || exit 1

echo "3. Ruby tests..."
bundle exec rspec || exit 1

echo "4. JavaScript tests..."
yarn test --ci || exit 1

echo "5. Security checks..."
bundle audit || exit 1
yarn audit || exit 1

echo "All quality checks passed! ✅"
```

Make it executable:
```bash
chmod +x scripts/quality-check.sh
./scripts/quality-check.sh
```

## IDE Integration

### VS Code Settings
Add to `.vscode/settings.json`:
```json
{
  "ruby.lint": {
    "rubocop": true
  },
  "eslint.autoFixOnSave": true,
  "editor.formatOnSave": true,
  "ruby.format": "rubocop",
  "files.associations": {
    "*.html.erb": "erb"
  }
}
```

### VS Code Tasks
Add to `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run RSpec",
      "type": "shell",
      "command": "bundle exec rspec",
      "group": "test"
    },
    {
      "label": "Run RuboCop",
      "type": "shell",
      "command": "bundle exec rubocop",
      "group": "build"
    },
    {
      "label": "Run Jest",
      "type": "shell",
      "command": "yarn test",
      "group": "test"
    }
  ]
}
```

## Troubleshooting

### Common Issues and Solutions

#### RSpec Issues
```bash
# Clear test database
RAILS_ENV=test bin/rails db:drop db:create db:migrate

# Fix spring issues
bin/spring stop

# Clear coverage files
rm -rf coverage/
```

#### Jest Issues
```bash
# Clear Jest cache
yarn test --clearCache

# Update snapshots
yarn test --updateSnapshot

# Debug specific test
yarn test --debug src/components/Article.test.jsx
```

#### RuboCop Issues
```bash
# Regenerate RuboCop TODO file
bundle exec rubocop --auto-gen-config

# Check RuboCop version compatibility
bundle exec rubocop --version

# Reset RuboCop cache
bundle exec rubocop --cache false
```

---

This reference should cover most testing and linting scenarios you'll encounter while developing Forem. Keep this handy for quick command lookups!