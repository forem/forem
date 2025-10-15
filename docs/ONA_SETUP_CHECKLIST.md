# Ona Preview Environment Setup Checklist

This checklist outlines the steps needed to fully enable Ona preview environments for pull requests in the Forem repository.

## ✅ Completed (via code changes)

These items have been completed through the automated setup:

- [x] Created `.gitpod.yml` with PR prebuild configuration
- [x] Created `.ona.yml` for Ona-specific configuration
- [x] Created `.ona/automations.yaml` for automation tasks
- [x] Created GitHub Action workflow (`.github/workflows/ona-preview.yml`)
- [x] Enabled PR comments and badges in Gitpod configuration
- [x] Created comprehensive documentation (`docs/ona_preview_environments.md`)
- [x] Configured Docker and docker-compose integration

## 🔧 Manual Steps Required

These steps require manual intervention by a repository administrator:

### 1. Install Gitpod/Ona GitHub App

**Priority: HIGH** - This is required for prebuilds to work

1. Visit: https://github.com/apps/gitpod-io
2. Click "Configure" or "Install"
3. Select the `forem/forem` repository (or your organization)
4. Grant the following permissions:
   - Read access to metadata
   - Read and write access to checks
   - Read and write access to pull requests
   - Read access to repository contents

**Verification**: After installation, you should see the Gitpod app in:
- Settings → Integrations → GitHub Apps

### 2. Configure GitHub Actions Permissions

**Priority: HIGH** - Required for the workflow to post comments

1. Go to repository Settings → Actions → General
2. Under "Workflow permissions", select:
   - ✅ "Read and write permissions"
3. Check:
   - ✅ "Allow GitHub Actions to create and approve pull requests"
4. Click "Save"

**Verification**: Check that the setting persists after saving.

### 3. Enable Ona/Gitpod for Organization (if applicable)

**Priority: MEDIUM** - May be required for organization repos

If the repository is under an organization:

1. Go to Organization Settings
2. Navigate to "GitHub Apps"
3. Find "Gitpod" in the installed apps
4. Ensure it has access to the `forem` repository
5. Configure organization-wide settings if desired

### 4. Set Up Prebuild Webhooks (Optional but Recommended)

**Priority: LOW** - Improves prebuild reliability

1. Go to https://gitpod.io/settings
2. Navigate to "Integrations" → "GitHub"
3. Ensure the Forem repository is connected
4. Enable prebuild triggers for:
   - Push events
   - Pull request events
   - Branch events

### 5. Configure Resource Limits (Optional)

**Priority: LOW** - Prevents resource exhaustion

In Gitpod/Ona dashboard:

1. Set workspace timeout (recommended: 30 minutes)
2. Set concurrent workspace limit
3. Configure automatic workspace deletion settings

### 6. Add GitHub Label (Optional)

**Priority: LOW** - For better organization

Create a label for prebuilt PRs:

1. Go to Issues → Labels → New Label
2. Name: `prebuilt-in-gitpod` or `prebuilt-in-ona`
3. Color: Choose a distinctive color (e.g., #6F42C1)
4. Description: "Preview environment is prebuilt and ready"
5. Create label

### 7. Test the Setup

**Priority: HIGH** - Verify everything works

1. Create a test branch:
   ```bash
   git checkout -b test-ona-preview
   git commit --allow-empty -m "Test Ona preview setup"
   git push origin test-ona-preview
   ```

2. Open a pull request from this branch

3. Verify the following:
   - [ ] GitHub Action runs successfully (check Actions tab)
   - [ ] Comment is added to PR with preview links
   - [ ] Gitpod prebuild check appears in PR checks
   - [ ] Clicking preview link opens Gitpod/Ona workspace
   - [ ] Workspace initializes and starts Rails server
   - [ ] Application is accessible on port 3000
   - [ ] Label is added when prebuild completes (if configured)

4. If successful, close the test PR

## 🔍 Verification Steps

After completing manual steps, verify each component:

### Verify GitHub App Installation

```bash
# Check via GitHub API (replace TOKEN and REPO)
curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/forem/forem/installation
```

Expected: Should return installation details

### Verify GitHub Action

1. Go to Actions tab
2. Select "Ona Preview Environment" workflow
3. Check recent runs for errors

### Verify Prebuild Configuration

1. Open any recent PR
2. Check PR checks section
3. Look for "Gitpod" or "Ona" status check

### Verify Comment Bot

1. Open any recent PR (created after setup)
2. Look for comment from `github-actions[bot]`
3. Verify it contains "🚀 Ona Preview Environment"

## 🐛 Troubleshooting

### GitHub App Not Appearing

**Problem**: Gitpod app not showing in installed apps

**Solution**:
1. Reinstall the app
2. Ensure you have admin permissions
3. Check organization settings if applicable

### Action Fails with Permission Error

**Problem**: Workflow can't post comments

**Solution**:
1. Verify Actions permissions (Step 2 above)
2. Check workflow file has correct permissions:
   ```yaml
   permissions:
     pull-requests: write
   ```
3. Re-run the workflow

### Prebuild Never Starts

**Problem**: No prebuild check appears on PRs

**Solution**:
1. Verify GitHub App installation
2. Check `.gitpod.yml` configuration
3. Ensure `pullRequests: true` is set
4. Check Gitpod dashboard for webhook errors

### Comment Not Added

**Problem**: Workflow runs but no comment appears

**Solution**:
1. Check workflow logs in Actions tab
2. Verify PAT or GITHUB_TOKEN has correct scopes
3. Ensure PR is not from a fork without approval (security feature)

### Workspace Fails to Start

**Problem**: Clicking link opens Gitpod but workspace errors

**Solution**:
1. Check `.gitpod.yml` syntax
2. Verify `Dockerfile` exists and builds successfully
3. Check `docker-compose.yml` is valid
4. Review Gitpod workspace logs for specific errors

## 📋 Next Steps After Setup

Once all manual steps are complete:

1. **Announce to team**: Inform contributors about the new feature
2. **Update contribution docs**: Add info about using preview environments
3. **Monitor usage**: Check Gitpod/Ona dashboard for metrics
4. **Gather feedback**: Ask team about their experience
5. **Optimize**: Adjust configuration based on usage patterns

## 📞 Getting Help

If you encounter issues:

1. **Check Gitpod documentation**: https://www.gitpod.io/docs
2. **Ona support**: Visit https://ona.dev/support
3. **GitHub Actions docs**: https://docs.github.com/en/actions
4. **Forem team**: Ask in internal channels
5. **Community**: Forem community forums or GitHub Discussions

## 📝 Post-Setup Maintenance

Regular maintenance tasks:

- **Weekly**: Check prebuild success rate
- **Monthly**: Review resource usage and costs
- **Quarterly**: Update configuration as project evolves
- **As needed**: Respond to issues and optimize settings

## 🎉 Success Criteria

You'll know the setup is complete when:

- ✅ Every new PR automatically gets a preview environment comment
- ✅ Prebuilds complete successfully within 10 minutes
- ✅ Team members can open and use preview environments easily
- ✅ No consistent errors in GitHub Actions or prebuild checks
- ✅ Documentation is clear and helpful

---

**Setup Date**: _____________

**Completed by**: _____________

**Notes**: _____________

