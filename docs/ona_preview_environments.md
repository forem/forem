# Ona Preview Environments for Pull Requests

This document describes how Ona (formerly Gitpod) preview environments are set up for Forem pull requests, enabling contributors and reviewers to test changes in a fully-configured cloud development environment.

## Overview

Ona preview environments provide:
- ✅ Fully configured development environment (Rails, PostgreSQL, Redis, etc.)
- ✅ Automatic environment setup and database seeding
- ✅ Pre-built environments for faster startup
- ✅ Easy PR review and testing without local setup
- ✅ Isolated environments for each PR branch

## How It Works

### For PR Authors

When you open a pull request, an Ona preview environment is automatically prepared:

1. **Automated Comment**: A GitHub Action automatically adds a comment to your PR with links to open the preview environment
2. **Prebuild Status**: A check runs to prebuild the environment (visible in PR checks)
3. **Ready to Use**: Click the link in the PR comment or the badge to open your preview environment

### For PR Reviewers

Reviewers can click the Ona preview link in any PR to:
- Test the changes in a real environment
- Verify functionality without setting up locally
- Review code and test features simultaneously

## Configuration Files

### `.gitpod.yml`

The main configuration file that Gitpod/Ona uses. This file:
- Configures ports (3000 for Rails, 5432 for PostgreSQL, 6379 for Redis)
- Sets up environment variables
- Runs initialization scripts (`dip provision`)
- Starts the development server
- Enables prebuilds for PRs

**Key Settings:**
```yaml
github:
  prebuilds:
    master: true              # Prebuild main branch
    pullRequests: true        # Prebuild all PRs
    pullRequestsFromForks: true  # Prebuild fork PRs
    addComment: true          # Add comment with preview link
    addBadge: true            # Add badge to PR
    addLabel: prebuilt-in-gitpod  # Label when ready
    addCheck: true            # Add status check
```

### `.ona.yml`

Ona-specific configuration file that provides:
- Enhanced port visibility settings
- Environment-specific configurations
- VSCode extension recommendations
- Optimized task sequences

### `.ona/automations.yaml`

Contains automation tasks that run in Ona environments:
- `install-dependencies`: Installs Ruby and Node.js dependencies
- `setup-environment`: Configures environment variables
- `start-services`: Starts development services
- `verify-setup`: Verifies the environment is correctly configured

### `.github/workflows/ona-preview.yml`

GitHub Action that:
- Triggers on PR open, sync, and reopen events
- Adds/updates a comment with preview links
- Provides both Gitpod and Ona URLs
- Includes usage instructions

## Setup Instructions

### Prerequisites

Before Ona preview environments work in your repository, you need:

1. **Install the Gitpod GitHub App**
   - Visit: https://github.com/apps/gitpod-io
   - Click "Configure"
   - Select your organization/repository (forem/forem)
   - Grant necessary permissions

2. **Configure Repository Settings**
   - Ensure Actions have permission to write to PRs
   - Go to: Settings → Actions → General → Workflow permissions
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

### Testing the Setup

1. **Create a test PR** from a feature branch
2. **Wait for the GitHub Action** to add a comment (usually within 30 seconds)
3. **Check for the prebuild status** in PR checks
4. **Click the preview link** to open the environment
5. **Wait for initialization** (first build: ~10 minutes, subsequent: ~2 minutes)

## Usage Guide

### Opening a Preview Environment

**From PR Comment:**
1. Navigate to your pull request
2. Find the "🚀 Ona Preview Environment" comment
3. Click either the "Open in Gitpod" button or "Open in Ona" link

**Direct URL:**
```
https://gitpod.io/#https://github.com/{username}/forem/tree/{branch-name}
```
or
```
https://ona.dev/#https://github.com/{username}/forem/tree/{branch-name}
```

### Environment Setup Time

- **First build**: ~10-15 minutes (full dependency installation)
- **Subsequent builds**: ~2-5 minutes (using prebuild cache)
- **With prebuild**: ~30-60 seconds (if prebuild completed)

### Accessing the Application

Once the environment starts:
1. Wait for "Forem development environment is ready!" message
2. A browser preview will automatically open on port 3000
3. If it doesn't auto-open, click the "Open Preview" button for port 3000

### Default Credentials

The seeded database includes default admin credentials (check `.env_sample` or setup scripts for specifics).

### Making Changes

Changes made in the preview environment:
- ✅ Are reflected immediately in the running application
- ✅ Can be tested in real-time
- ❌ Are NOT automatically pushed to your branch
- ❌ Are NOT persisted after the workspace closes

To persist changes, you must commit and push them from within the Ona environment.

## Troubleshooting

### Preview Link Not Appearing

**Issue**: No comment added to PR

**Solutions**:
1. Check that GitHub Actions has write permissions (see Setup Instructions)
2. Verify the workflow file exists at `.github/workflows/ona-preview.yml`
3. Check Actions tab for workflow execution errors

### Environment Fails to Start

**Issue**: Environment times out or fails during initialization

**Solutions**:
1. Check the terminal output for specific errors
2. Try rebuilding: Cmd/Ctrl + Shift + P → "Rebuild Workspace"
3. Verify `.env_sample` exists and is valid
4. Check that `dip provision` runs successfully

### Port 3000 Not Opening

**Issue**: Server starts but preview doesn't open

**Solutions**:
1. Manually open the preview: Click "Ports" tab → Right-click port 3000 → "Open Preview"
2. Check terminal for Rails server errors
3. Verify environment variables are set correctly

### Database Issues

**Issue**: Database connection errors or migration failures

**Solutions**:
1. Ensure PostgreSQL service is running (check docker-compose)
2. Run manually: `dip rails db:create db:migrate db:seed`
3. Check DATABASE_URL environment variable

### Dependencies Not Installing

**Issue**: Bundle or Yarn errors during setup

**Solutions**:
1. Check Ruby version compatibility
2. Clear caches: `rm -rf node_modules && yarn install`
3. Rebuild Bundler: `bundle install --full-index`

## Architecture

### Service Stack

The Ona environment includes:
- **Web Server**: Rails server on port 3000
- **Database**: PostgreSQL 13 on port 5432
- **Cache**: Redis 7.0 on port 6379
- **Assets**: esbuild for JavaScript bundling
- **Background Jobs**: Sidekiq for job processing

### Docker Configuration

Uses:
- `docker-compose.yml` for service orchestration
- `Containerfile` for building the application image
- `dip` (Docker Interaction Process) for simplified commands

### Environment Variables

Key variables automatically configured:
- `APP_DOMAIN`: Set to the Ona workspace URL
- `APP_PROTOCOL`: Set to "https://"
- `COMMUNITY_NAME`: Set to "DEV(Ona Preview)"
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string

## Best Practices

### For Contributors

1. **Open preview early**: Start the environment while you write PR description
2. **Test before requesting review**: Verify changes work in preview
3. **Include preview link in PR description**: Help reviewers find it
4. **Close workspaces**: Stop workspaces when done to save resources

### For Reviewers

1. **Use preview for functional review**: Test features without local setup
2. **Check code and functionality together**: Review while testing
3. **Leave comments on code**: Use GitHub's review feature
4. **Don't rely solely on preview**: Still review code carefully

### For Maintainers

1. **Monitor prebuild success rate**: Check Actions tab regularly
2. **Update configuration as needed**: Keep pace with project changes
3. **Review resource usage**: Monitor Ona/Gitpod quotas
4. **Keep documentation updated**: Update this doc when configuration changes

## FAQ

**Q: Does every PR get a preview environment?**
A: Yes, all PRs (including from forks) have prebuilds enabled.

**Q: How long does the environment stay active?**
A: Inactive workspaces timeout after 30 minutes (default Gitpod setting).

**Q: Can I use this for development?**
A: Yes! Use the same URLs replacing `{username}/forem` with your fork.

**Q: What happens to my data when workspace closes?**
A: Data is lost unless committed and pushed. The environment is ephemeral.

**Q: Can I customize my preview environment?**
A: Yes, you can modify `.gitpod.yml` or `.ona.yml` in your branch.

**Q: Is this free?**
A: Gitpod/Ona offers free hours per month. Check their pricing for limits.

**Q: Can I open multiple PRs simultaneously?**
A: Yes, each PR gets its own isolated environment.

**Q: How do I update environment variables?**
A: Modify `.env` in the running workspace or update `.gitpod.yml`/`.ona.yml` for permanent changes.

## Additional Resources

- [Gitpod Documentation](https://www.gitpod.io/docs)
- [Ona Documentation](https://ona.dev/docs)
- [Forem Contributing Guide](https://developers.forem.com/contributing-guide/forem)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Dip Documentation](https://github.com/bibendi/dip)

## Maintenance Notes

**Last Updated**: October 14, 2025

**Configuration Files to Update When:**
- Changing ports: Update `.gitpod.yml` and `.ona.yml` ports section
- Adding services: Update `docker-compose.yml` and port configurations
- Modifying setup: Update `.ona/automations.yaml` tasks
- Changing environment variables: Update initialization scripts

**Monitoring Checklist:**
- [ ] Prebuild success rate > 90%
- [ ] Average startup time < 3 minutes
- [ ] GitHub Action execution success > 95%
- [ ] No resource quota warnings
- [ ] Documentation reflects current setup

