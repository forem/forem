# Contributing to dev.to

- [Contributing](#contributing)
  - [Where to contribute](#where-to-contribute)
  - [How to contribute](#how-to-contribute)
  - [Contribution guideline](#contribution-guideline)
    - [Clean code with tests](#clean-code-with-tests)
    - [Create a pull request](#create-a-pull-request)
    - [Create an issue](#create-an-issue)
  - [How to get help](#how-to-get-help)
  - [The bottom line](#the-bottom-line)

## Contributing

We expect contributors to abide by our underlying [code of conduct](https://dev.to/code-of-conduct). All conversations and discussions on GitHub (issues, pull requests) and across dev.to must be respectful and harassment-free.

### Where to contribute

All [issues](https://github.com/thepracticaldev/dev.to/issues) labeled with `approved` are up for grabs. For clarification on how we label issues, check out their definitions [here](https://github.com/thepracticaldev/dev.to/labels).

When in doubt, ask a [core team member](https://github.com/thepracticaldev/dev.to/#core-team)! You can mention us in any issues or ask on the [DEV Contributor thread](https://dev.to/devteam/devto-open-source-helpdiscussion-thread-v0-1l45). Any issue with the `good first issue` tag is typically a good place to start for anyone new to the project. For newer developers, try `entry-level` issues.

**Refactoring** code, e.g. improving the code without modifying the behavior is an area that can probably be done based on intuition and may not require much communication to be merged.

**Fixing bugs** may also not require a lot of communication, but the more the better. Please surround bug fixes with ample tests. Bugs are magnets for other bugs. Write tests near bugs!

**Building features** is the area which will require the most communication and/or negotiation. Every feature is subjective and open for debate. If your feature involves user-facing design changes, please provide a mockup first so we can all get on the same page. As always, when in doubt, ask!

### How to contribute

1. Fork the project & clone locally. Follow the initial setup [here](https://github.com/thepracticaldev/dev.to/#getting-started).
2. Create a branch, naming it either a feature or bug: `git checkout -b feature/that-new-feature` or `bug/fixing-that-bug`
3. Code and commit your changes. Bonus points if you write a [good commit message](https://chris.beams.io/posts/git-commit/): `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/that-new-feature`
5. [Create a pull request](https://github.com/thepracticaldev/dev.to/#create-a-pull-request) for your branch 🎉

## Contribution guideline

### Create an issue

Nobody's perfect. Something doesn't work? Or could be done better? Let us know by creating an issue.

PS: a clear and detailed issue gets lots of love, all you have to do is follow the issue template!

#### Clean code with tests

Some existing code may be poorly written or untested, so we must have more scrutiny going forward. We test with [rspec](http://rspec.info/), let us know if you have any questions about this!

#### Create a pull request

- Try to keep the pull requests small. A pull request should try its very best to address only a single concern.
- Make sure all tests pass and add additional tests for the code you submit. [More info here](https://docs.dev.to/tests/)
- Document your reasoning behind the changes. Explain why you wrote the code in the way you did. The code should explain what it does.
- If there's an existing issue related to the pull request, reference to it by adding something like `References/Closes/Fixes/Resolves #305`, where 305 is the issue number. [More info here](https://github.com/blog/1506-closing-issues-via-pull-requests)
- If you follow the pull request template, you can't go wrong.

_Please note: all commits in a pull request will be squashed when merged, but when your PR is approved and passes our CI, it will be live on production!_

### How to get help

Whether you are stuck with feature implementation, first-time setup, or you just want to tell us something could be done better, check out our [OSS thread](https://dev.to/devteam/devto-open-source-helpdiscussion-thread-v0-1l45) or create an issue. You can also mention any [core team member](https://github.com/thepracticaldev/dev.to/#core-team) in an issue and we'll respond as soon as possible.

### 👉 [OSS Help/Discussion Thread](https://dev.to/devteam/devto-open-source-helpdiscussion-thread-v0-1l45) 👈

### The bottom line

We are all humans trying to work together to improve the community. Always be kind and appreciate the need for tradeoffs. ❤️
