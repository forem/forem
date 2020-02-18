# Maintainer Processes

This document contains basic instructions for the maintainers of the DEV
application. It's a work in-progress, but should allow the DEV Core Team to
document processes and strategies in a transparent way!

# Skipping CI

Some small PRs might seem like good candidates for skipping the CI suite. For
example, a change that only touches documentation copy or a tiny CSS tweak.

For the time being, we should avoid skipping CI in PRs because it causes some
confusion during the review process. However, it does make sense to skip CI on
merge commits that include extremely minor changes.

You can skip CI by appending [ci skip] to merge commit's message.

When in doubt, don't skip CI.

# Pull Request Review

At the moment, our PR review process is being evaluated, so this is subject to
change.

Before a PR is merged we expect:

- every contributor to sign our CLA
- all of the automated checks to pass
- approval from at least two members of the Core Team

PR review is the Core Team's opportunity to weigh-in on changes before they go
into master.

Keep in mind that our team is distributed across the world. It's a good idea to
leave far-reaching PRs open for a day, to give everyone a change to share their
thoughts.

# Merging Pull Requests

At the time of writing, we tend to prefer squashing PRs into a single commit and
merging them. This is easily (and safely) achieved using the GitHub UI.

# Deploying DEV

If the application needs to be deployed when the code is merged, appending
[deploy] to the merge commit's message will trigger a deploy.

Generally, it's a good idea to keep the SRE team in the loop on any deploys.
