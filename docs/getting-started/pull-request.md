---
title: Preparing a Pull Request
---

# Preparing a pull request

- Try to keep the pull requests small. A pull request should try its very best
  to address only a single concern.
- If you plan to do further work after the PR is submit, please use the
  [Draft PR](https://github.blog/2019-02-14-introducing-draft-pull-requests/)
  feature.
- Make sure all tests pass and add additional tests for the code you submit.
  [More info here](https://docs.dev.to/tests/).
- Document your reasoning behind the changes. Explain why you wrote the code in
  the way you did. The code should explain what it does.
- If there's an existing issue related to the pull request, reference to it by
  adding something like `References/Closes/Fixes/Resolves #305`, where 305 is
  the issue number.
  [More info here](https://github.com/blog/1506-closing-issues-via-pull-requests).
- Please fill out the PR Template when making a PR.
- All commits in a pull request will be squashed when merged, but when your PR
  is approved and passes our CI, it will eventually be live on production!

If the pull request affects the public API in any way, a post on DEV from the
DEV Team account should accompany it. This is the duty of the core team to carry
out.
