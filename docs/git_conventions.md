# Git Conventions for Forem

This document outlines the Git workflow conventions for the Forem project, including branch naming, commit messages, and pull request guidelines.

## Branch Naming Conventions

### Standard Format
```
[initials]/[type]-[short-description]
```

### Getting Your Initials
**IMPORTANT**: Always run `git config user.name` first to get your actual name - do not assume or guess the initials.

```bash
# Get your git username
git config user.name
# Example output: "John Doe"

# Extract initials: first letter of each word
# "John Doe" → "jd"
# "Alice Smith Johnson" → "asj"
# "Mary-Jane Watson" → "mjw"
```

### Branch Types

#### Feature Branches
For new features or enhancements:
```
jd/feature-user-bookmarks
sm/feature-dark-mode-toggle
ak/feature-article-templates
```

#### Bug Fix Branches
For fixing bugs:
```
jd/fix-article-rendering
sm/fix-login-redirect
ak/fix-mobile-navigation
```

#### Refactor Branches
For code refactoring without changing functionality:
```
jd/refactor-user-service
sm/refactor-article-queries
ak/refactor-component-structure
```

#### Hotfix Branches
For urgent production fixes:
```
jd/hotfix-security-vulnerability
sm/hotfix-payment-processing
ak/hotfix-database-connection
```

#### Documentation Branches
For documentation updates:
```
jd/docs-api-endpoints
sm/docs-deployment-guide
ak/docs-testing-setup
```

### Branch Naming Rules

#### Length Limits
- **Maximum 50 characters total**
- Keep descriptions concise but descriptive
- Use hyphens to separate words in descriptions

#### Valid Examples
```bash
# Good examples
jd/feature-user-notifications
sm/fix-article-search-bug
ak/refactor-auth-service
mj/docs-contributing-guide

# Bad examples (too long, unclear, or wrong format)
john-doe/add-user-notification-system-with-email-preferences  # Too long
jd/stuff                                                      # Too vague
fix-bug                                                       # Missing initials
jd_feature_notifications                                      # Wrong separator
```

#### Special Cases
```bash
# Issue-based branches (include issue number)
jd/123-fix-article-rendering
sm/456-feature-user-dashboard

# Experimental branches
jd/experiment-new-search-algorithm
sm/spike-graphql-integration

# Dependency updates
jd/update-rails-version
sm/bump-node-dependencies
```

## Commit Message Conventions

### Standard Format
```
<type>: <subject>

<body>

<footer>
```

### Commit Types

#### Primary Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring without changing functionality
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates

#### Secondary Types
- **perf**: Performance improvements
- **security**: Security-related changes
- **ci**: CI/CD configuration changes
- **build**: Build system or dependency changes
- **revert**: Reverting previous commits

### Subject Line Rules

#### Format Requirements
- **Maximum 50 characters**
- Start with lowercase letter
- No period at the end
- Use imperative mood ("add" not "added" or "adds")

#### Good Examples
```
feat: add user notification preferences
fix: resolve article rendering issue with code blocks
docs: update API documentation for user endpoints
refactor: extract article publishing logic to service
test: add comprehensive tests for user authentication
```

#### Bad Examples
```
Added user notifications                    # Wrong tense
Fix bug                                    # Too vague
feat: Added a new feature for users to be able to customize their notification preferences  # Too long
Fixed the bug where articles weren't rendering properly.  # Wrong tense + period
```

### Commit Body Guidelines

#### When to Include Body
- Complex changes that need explanation
- Breaking changes
- Multiple related changes
- Context about why the change was made

#### Body Format
- Wrap at 72 characters per line
- Explain **what** and **why**, not **how**
- Use bullet points for multiple changes
- Reference issues and pull requests

#### Example with Body
```
feat: add user bookmark functionality

- Allow users to bookmark articles for later reading
- Add bookmark model with user and article associations
- Include bookmark toggle button on article pages
- Add bookmarks index page for users to manage saved articles

This addresses the frequently requested feature for users to save
articles they want to read later. The implementation uses a simple
many-to-many relationship between users and articles.

Closes #1234
Related to #5678
```

### Footer Conventions

#### Issue References
```
# Closes issues
Closes #123
Closes #123, #456, #789

# References issues without closing
Refs #123
Related to #456
See also #789
```

#### Breaking Changes
```
BREAKING CHANGE: User authentication now requires email verification

This change modifies the user registration flow to require email
verification before account activation. Existing users are not
affected, but new registrations will need to verify their email.
```

#### Co-authorship
**IMPORTANT**: Always include Ona Agent co-authorship for AI-assisted commits:
```
Co-authored-by: Ona <no-reply@ona.com>
```

### Complete Commit Examples

#### Simple Feature
```
feat: add article reading time estimation

Calculate and display estimated reading time based on word count
and average reading speed of 200 words per minute.

Co-authored-by: Ona <no-reply@ona.com>
```

#### Bug Fix
```
fix: resolve N+1 query in article index page

- Add includes(:user, :tags) to article query
- Reduce database queries from ~100 to 3
- Improve page load time by approximately 60%

The previous implementation was causing performance issues on pages
with many articles due to individual queries for each article's
user and tags.

Fixes #2345
Co-authored-by: Ona <no-reply@ona.com>
```

#### Refactoring
```
refactor: extract article publishing logic to service

- Move publishing logic from Article model to ArticlePublisher service
- Add comprehensive error handling and validation
- Improve testability and separation of concerns
- Maintain backward compatibility with existing API

This refactoring prepares for upcoming scheduled publishing feature
and makes the publishing logic more maintainable.

Co-authored-by: Ona <no-reply@ona.com>
```

#### Documentation
```
docs: add comprehensive API documentation for articles endpoint

- Document all CRUD operations for articles
- Include request/response examples
- Add authentication requirements
- Document error responses and status codes

Co-authored-by: Ona <no-reply@ona.com>
```

## Pull Request Guidelines

### PR Title Format
Use the same format as commit messages:
```
feat: add user notification preferences
fix: resolve article rendering issue
docs: update deployment documentation
```

### PR Description Template
The project uses a PR template (`.github/PULL_REQUEST_TEMPLATE.md`). Always fill it out completely:

```markdown
## What type of PR is this? (check all applicable)
- [x] Feature
- [ ] Bug Fix
- [ ] Refactor
- [ ] Documentation Update

## Description
Brief description of what this PR does and why.

## Related Tickets & Documents
- Closes #1234
- Related to #5678

## QA Instructions, Screenshots, Recordings
Step-by-step instructions for testing the changes.

## Added/updated tests?
- [x] Yes
- [ ] No, and this is why: [explanation]
```

### PR Size Guidelines

#### Ideal PR Size
- **Small PRs**: 1-100 lines changed (preferred)
- **Medium PRs**: 100-500 lines changed (acceptable)
- **Large PRs**: 500+ lines changed (avoid when possible)

#### Breaking Down Large PRs
```bash
# Instead of one large PR, create multiple smaller ones:

# PR 1: Database migration and model changes
jd/feature-bookmarks-models

# PR 2: Controller and API endpoints
jd/feature-bookmarks-api

# PR 3: Frontend components
jd/feature-bookmarks-ui

# PR 4: Integration and final touches
jd/feature-bookmarks-integration
```

## Git Workflow Best Practices

### Daily Workflow

#### Starting Work
```bash
# 1. Switch to main and pull latest changes
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b jd/feature-user-dashboard

# 3. Make your changes and commit frequently
git add .
git commit -m "feat: add user dashboard skeleton"

# 4. Push branch regularly
git push origin jd/feature-user-dashboard
```

#### During Development
```bash
# Make small, focused commits
git add app/models/dashboard.rb
git commit -m "feat: add dashboard model with user association"

git add spec/models/dashboard_spec.rb
git commit -m "test: add comprehensive dashboard model tests"

git add app/controllers/dashboards_controller.rb
git commit -m "feat: add dashboard controller with CRUD operations"
```

#### Before Creating PR
```bash
# 1. Rebase on latest main
git checkout main
git pull origin main
git checkout jd/feature-user-dashboard
git rebase main

# 2. Run quality checks
bundle exec rspec
yarn test
bundle exec rubocop
yarn lint:frontend

# 3. Push final changes
git push origin jd/feature-user-dashboard --force-with-lease
```

### Commit Frequency

#### When to Commit
- After completing a logical unit of work
- Before switching contexts or taking breaks
- After fixing a bug or adding a feature
- Before attempting risky changes

#### Atomic Commits
Each commit should represent one logical change:
```bash
# Good: separate commits for separate concerns
git commit -m "feat: add user model validation"
git commit -m "test: add user model validation tests"
git commit -m "docs: update user model documentation"

# Bad: mixing unrelated changes
git commit -m "feat: add user validation, fix article bug, update docs"
```

### Merge vs. Rebase

#### When to Rebase
- Before creating a PR (clean up history)
- When updating feature branch with main
- For personal/feature branches

```bash
# Rebase feature branch on main
git checkout jd/feature-user-dashboard
git rebase main
```

#### When to Merge
- Merging PRs into main (done by maintainers)
- Integrating completed features
- Preserving collaboration history

### Handling Conflicts

#### Resolving Merge Conflicts
```bash
# During rebase
git rebase main
# Fix conflicts in files
git add .
git rebase --continue

# During merge
git merge main
# Fix conflicts in files
git add .
git commit -m "resolve merge conflicts with main"
```

#### Preventing Conflicts
- Rebase frequently on main
- Communicate about overlapping work
- Keep PRs small and focused
- Coordinate on shared files

## Advanced Git Techniques

### Interactive Rebase
Clean up commit history before creating PR:
```bash
# Rebase last 3 commits interactively
git rebase -i HEAD~3

# Options in interactive rebase:
# pick = use commit as-is
# reword = change commit message
# edit = stop to amend commit
# squash = combine with previous commit
# drop = remove commit
```

### Commit Amending
Fix the last commit:
```bash
# Add forgotten files to last commit
git add forgotten_file.rb
git commit --amend --no-edit

# Change last commit message
git commit --amend -m "feat: add user dashboard with proper validation"
```

### Cherry Picking
Apply specific commits to another branch:
```bash
# Apply commit from another branch
git cherry-pick abc123def

# Apply multiple commits
git cherry-pick abc123def..xyz789abc
```

### Stashing Changes
Temporarily save work in progress:
```bash
# Stash current changes
git stash push -m "work in progress on user dashboard"

# List stashes
git stash list

# Apply stash
git stash pop

# Apply specific stash
git stash apply stash@{1}
```

## Tools and Automation

### Git Hooks
Set up pre-commit hooks to enforce quality:
```bash
# .git/hooks/pre-commit
#!/bin/sh
bundle exec rubocop --parallel
yarn lint:frontend
```

### Git Aliases
Add to `~/.gitconfig`:
```ini
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
    
    # Useful aliases for this workflow
    feature = "!f() { git checkout -b $(git config user.name | sed 's/\\(\\w\\)\\w* */\\L\\1/g')/feature-$1; }; f"
    fix = "!f() { git checkout -b $(git config user.name | sed 's/\\(\\w\\)\\w* */\\L\\1/g')/fix-$1; }; f"
```

### VS Code Integration
Configure VS Code for better Git workflow:
```json
{
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.enableSmartCommit": true,
  "gitlens.currentLine.enabled": false,
  "gitlens.hovers.currentLine.over": "line"
}
```

## Troubleshooting Common Issues

### Branch Issues
```bash
# Delete local branch
git branch -d jd/feature-old-feature

# Delete remote branch
git push origin --delete jd/feature-old-feature

# Rename current branch
git branch -m jd/feature-new-name

# Track remote branch
git branch --set-upstream-to=origin/jd/feature-name
```

### Commit Issues
```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Revert commit (create new commit that undoes changes)
git revert abc123def
```

### Remote Issues
```bash
# Update remote URL
git remote set-url origin https://github.com/forem/forem.git

# Add upstream remote (for forks)
git remote add upstream https://github.com/forem/forem.git

# Fetch from upstream
git fetch upstream
```

---

Following these Git conventions ensures a clean, maintainable project history and smooth collaboration among all contributors to the Forem project.