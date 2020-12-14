---
title: Code Climate
---

# Code Climate

We are using [Code Climate](https://codeclimate.com/github/forem/forem) to track
code quality and coverage.

Code Climate offers metrics regarding code quality for each individual PR,
however, it does not calculate these metrics for the entirety of the project. If
you'd like update the current linting rule, feel free to submit a PR to change
it.

Before merging a PR to Forem, we expected Code Climate to pass on that PR. If
you find Code Climate raising errors on your PR, please fix those issues. Do
your best to leave code in a better state than you found it!

We don't want to make a habit of pandering to Code Climate and its metrics
blindly, so if you're in doubt regarding a suggestion on your PR please start a
conversation in the PR comments.

Generally speaking, if you're looking for opportunities to contribute to the
project, but you don't have an issue you're interested in solving, improving the
Code Climate metrics is a good place to start. We're happy to see PRs that
refactor existing code to reduce duplication and increase readability, given
that those refactors are well tested.
