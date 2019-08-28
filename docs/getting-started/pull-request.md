---
title: Preparing a Pull Request
---

# Preparing a pull request

- Try to keep the pull requests small. A pull request should try its very best to address only a single concern.
- Make sure all tests pass and add additional tests for the code you submit. Checkout the [testing guide](/tests).
- Document your reasoning behind the changes. Explain why you wrote the code in the way you did. The code should be clear enough to explain what it does.
- If there's an existing issue related to the pull request, reference to it by adding something like `References/Closes/Fixes/Resolves #305`, where 305 is the issue number. See [GitHub's own guide on closing issues via PR](https://github.com/blog/1506-closing-issues-via-pull-requests).
- If you follow the pull request template, you can't go wrong.

_Please note: all commits in a pull request will be squashed when merged, but when your PR is approved and passes our CI, it will be live on production!_
