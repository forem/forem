---
title: Suggested Workflow
---

# Suggested workflow

We use [Spring](https://github.com/rails/spring), and it is already included in
the project.

1.  Use the provided bin stubs to automatically start Spring, i.e.
    `bin/rails server`, `bin/rspec spec/models/`, `bin/rails db:migrate`.
1.  If Spring isn't picking up on new changes, use `spring stop`. For example,
    Spring should always be restarted if there's a change in the environment
    keys.
1.  Check Spring's status whenever with `spring status`.

Caveat: `bin/rspec` is not equipped with Spring because it affects Simplecov's
result. Instead, use `bin/spring rspec`.

## Synchronizing a fork with upstream / integrate latest changes

When changes in the upstream repository happen, the fork does not get those
automatically and this is by design. To integrate the changes to the upstream
repo that were committed since you cloned your fork or synced the last time, use
the following script: `./scripts/sync_fork.sh` This will fetch the changes and
merge them into your current workspace.

Use this:

- to get commits from upstream main into your branch
- to sync with latest changes from upstream main before continuing with a new
  feature on your current branch

After you've fetched new commits from upstream, run `./bin/setup`, and it will
install new gems, npm packages, update database, and restart Rails server.

Start the app by running `./bin/startup`, if it's not already running.

## Start over / discard all your changes

Sometimes it is neccesarry to start over from the beginning or reset the current
workspace to the state of the upstream branch. Use the helper
`./scripts/clean_fork.sh` to set your fork to the exact same state as the
upstream main branch.

Use this:

- before working on a new feature
- before creating a new branch to make sure to have all the latest changes in
  your fork also.

After you've done that, run `./bin/setup`, and it will update gems, npm
packages, update database, and restart Rails server.

Start the app by running `./bin/startup`, if it's not already running.
