# Contributing to dev.to

- [Contributing](#contributing)
  - [Where to contribute](#where-to-contribute)
  - [How to contribute](#how-to-contribute)
  - [Contribution guideline](#contribution-guideline)
    - [Create an issue](#create-an-issue)
    - [Clean code with tests](#clean-code-with-tests)
    - [Create a pull request](#create-a-pull-request)
    - [Pull requests reviews and "force pushing"](#pull-requests-reviews-and-force-pushing)
  - [The bottom line](#the-bottom-line)

## Contributing

We expect contributors to abide by our underlying [code of conduct](https://dev.to/code-of-conduct). All conversations and discussions on GitHub (issues, pull requests) and across dev.to must be respectful and harassment-free.

### Where to contribute

All [issues](https://github.com/thepracticaldev/dev.to/issues) labeled with `help wanted` are up for grabs.

- `good first issue` are issues meant for newer developers.
- `type: discussion` are issues we haven't decided to move forward with, or need more information before proceeding.

While PRs without an associated `help wanted` issue may still be merged, please note that the core team will prioritize PRs that solve existing issues first. We strongly encourage creating an issue before working on a PR!

When in doubt, ask a [core team member](https://github.com/thepracticaldev/dev.to/#core-team) by mentioning us on the issue.

**Refactoring** code, e.g., improving the code without modifying the behavior is an area that can probably be done based on intuition and may not require much communication to be merged.

**Fixing bugs** may also not require a lot of communication, but the more, the better. Please surround bug fixes with ample tests. Bugs are magnets for other bugs. Write tests near bugs!

**Building features** is the area which will require the most communication and/or negotiation. Every feature is subjective and open for debate. If your feature involves user-facing design changes, please provide a mockup first so we can all get on the same page. As always, when in doubt, ask!

### How to contribute

1. Fork the project & clone locally. Follow the initial setup [here](https://github.com/thepracticaldev/dev.to/#getting-started).
2. Create a branch with your GitHub username as a prefix and the ID of the [issue](https://github.com/thepracticaldev/dev.to/issues) as a suffix, for example: `git checkout -b USERNAME/that-new-feature-1234` or `git checkout -b USERNAME/fixing-that-bug-1234` where `USERNAME` should be replaced by your username and `1234` is the ID of the issue tied to your pull request. If there is no issue, you can leave the number out.
3. Code and commit your changes. Bonus points if you write a [good commit message](https://chris.beams.io/posts/git-commit/): `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin USERNAME/that-new-feature-1234`
5. [Create a pull request](https://docs.dev.to/getting-started/pull-request/) for your branch 🎉

## Contribution guideline

### Create an issue

Nobody's perfect. Something doesn't work? Or could be done better? Check to see if the issue already exists and if it does, leave a comment to get our attention! And if the issue doesn't exist already, feel free to create a new one. A core team member will triage incoming issues.

_Please note: core team members may update the title of an issue to more accurately reflect the request/bug._

### Clean code with tests

Some existing code may be poorly written or untested, so we must have more scrutiny going forward. We test with [rspec](http://rspec.info/).

### Create a pull request

- Try to keep the pull requests small. A pull request should try its very best to address only a single concern.
- Make sure all tests pass and add additional tests for the code you submit. [More info here](https://docs.dev.to/tests/).
- Document your reasoning behind the changes. Explain why you wrote the code in the way you did. The code should explain what it does.
- If there's an existing issue related to the pull request, reference to it by adding something like `References/Closes/Fixes/Resolves #305`, where 305 is the issue number. [More info here](https://github.com/blog/1506-closing-issues-via-pull-requests).
- Please fill out the PR Template when making a PR.
- All commits in a pull request will be squashed when merged, but when your PR is approved and passes our CI, it will be live on production!

_Please note: a core team member may close your PR if it has gone stale or if we don't plan to merge the code._

### Pull requests reviews and "force pushing"

After you submit your pull request (PR), one of the members of the core team or core contributors will likely do a review of the code accepting it or giving feedback.

If feedback or suggestions are provided, any following modifications on your part should happen in separate commits added to the existing ones.

Force pushing, though understandable for reasons of wanting to keep the history clean, has some drawbacks:

- it removes the review history of the code
- forces the reviewer to start from scratch when adding possible further comments

PRs will be squashed and merged into master, so there's no need to use force push.

Please avoid force pushing unless you are in need to do a rebase from master.

## The bottom line

We are all humans trying to work together to improve the community. Always be kind and appreciate the need for tradeoffs. ❤️
