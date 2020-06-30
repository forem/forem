---
title: Pull Requests
---

# Pull Requests

## General

- We generally follow a branch naming convention of
  `<user>/<feature>-<issue number>`, e.g. `sloan/make-things-awesome-5555`.
  Issue numbers can be omitted when unavailable, e.g. for things like quick
  fixes, spikes, experiments, etc.
- Push early and often, you don’t need to wait until you’re finished to get
  feedback. Please use GitHub draft PRs when you have a work-in-progress (WIP)
  PR, or when you have a PR that is contingent on something else to be merged.
  We prefer draft PRs rather than adding "DO NOT MERGE" to a PR's title. Any PR
  that is not a draft should be ready to be merged by anyone once it has been
  reviewed.
- Please follow our pull request template. Provide context for reviewers, when
  in doubt err on the side of too much information.
- Core team members are not required to review draft PRs. To explicitly request
  feedback, please assign or mention people.

## PR Reviews

PR review is the Core Team's opportunity to weigh-in on changes before they go
into production.

Keep in mind that our team is distributed across the world. It's a good idea to
leave far-reaching PRs open for a day, to give everyone a change to share their
thoughts.

- We require 2 approvals from core team members for each PR:
  - One from the same team because they have context and are working towards the
    same goal as you.
  - One from outside your team for the following reasons:
    - A different perspective from someone who has less context
    - To leverage our different strengths and garner additional insights
      spreading knowledge and code exposure throughout the team
    - To avoid overloading individuals
- Tag people that you’d like to review your PR using GitHub’s ‘Reviewers’
  function.
- Be kind! The goal here is to work together on shipping good code, not to judge
  people.
- For serious issues, use Github’s “Request changes” feature. This should be
  reserved for serious problems, e.g.
  - Doesn’t do what the issue said
  - Foreseeable performance problems
  - Provable security issues
  - Breaks existing functionality
- Everything else can be posted as a comment, but it’s up to the original PR
  author whether or not they want to incorporate the changes.
- Please keep style discussions to an absolute minimum, that time is better
  spent making a PR for the configuration of our various lint tools.
- If you make changes to your PR, please re-request feedback from previous
  reviewers.

# Merging Pull Requests

At the time of writing, we tend to prefer squashing PRs into a single commit and
merging them. This is easily (and safely) achieved using the GitHub UI.

All required checks such as CI and Code Climate should be green.

Once a PR is merged, it might need to be deployed. Deployment is a team
responsibility, and everyone on the core team should be comfortable deploying
code. For more information, read the
[deployment guide](https://docs.dev.to/maintainers/deployment).
