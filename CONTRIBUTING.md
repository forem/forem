# Contributing to dev.to

- [Contributing](#contributing)
  - [Where to contribute](#where-to-contribute)
  - [How to contribute](#how-to-contribute)
  - [Contribution guideline](#contribution-guidelines)
    - [Create an issue](#create-an-issue)
    - [Please include tests](#please-include-tests)
    - [Code quality](#code-quality)
    - [Create a pull request](#create-a-pull-request)
    - [Pull requests reviews and "force pushing"](#pull-requests-reviews-and-force-pushing)
  - [The bottom line](#the-bottom-line)

## Contributing

We expect contributors to abide by our underlying
[code of conduct](https://dev.to/code-of-conduct). All conversations and
discussions on GitHub (issues, pull requests) and across
[https://dev.to](dev.to) must be respectful and harassment-free.

Remember that communication is the lifeblood of any Open Source project. We are
all working on this together, and we are all benefiting from this software. It's
very easy to misunderstand one another over asynchronous, text-based
conversations: When in doubt, assume everyone you're interacting within this
project has the best intentions.

If you feel another member of the community has violated our Code of Conduct,
you may anonymously contact the team with our
[abuse report form](https://dev.to/report-abuse).

### Where to contribute

All [issues](https://github.com/thepracticaldev/dev.to/issues) labeled
[ready for dev](https://github.com/thepracticaldev/dev.to/issues?q=is%3Aissue+is%3Aopen+label%3A%22ready+for+dev%22)
and
[type: bug](https://github.com/thepracticaldev/dev.to/issues?q=is%3Aissue+is%3Aopen+label%3A%22type%3A+bug%22)
all are up for grabs.

- [good first issue](https://github.com/thepracticaldev/dev.to/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22+)
  are issues meant for newer developers.

While PRs without an associated `ready for dev` or `type: bug` labeled issue may
still be merged, please note that the core team will prioritize PRs that solve
existing issues. We strongly encourage creating an issue before working on a PR!

When in doubt, ask a
[core team member](https://github.com/thepracticaldev/dev.to/#core-team) by
mentioning us on the issue.

**Documentation** is almost always a great place to start contributing to a new
project. DEV is an Open Source, community-driven project, so providing and
maintaining quality documentation is one of our most important jobs. You can
find more information about contributing to the documentation in the
[docs/ directory](https://github.com/thepracticaldev/dev.to/blob/master/docs/contributing.md)!

**Refactoring** code, or improving the code without modifying the behaviour, is
an area that can probably be done based on intuition and may not require much
communication to be merged. Generally speaking, you can rely on existing tests
to ensure that your refactoring doesn't introduce any unexpected behaviour.
However, you might be asked to write a regression test if the area you've
refactored isn't well covered. As refactoring can span many files it's always
encouraged to proceed in steps if possible by submitting multiple smaller PRs.

**Fixing bugs** may also not require a lot of communication, but it's always
better to let us know what you're working on! Please surround bug fixes with
ample tests; bugs are magnets for other bugs. Write tests around bugs!

**Building features** is the area that will require the most communication
and/or negotiation. Every feature is subjective and open for debate. If your
feature involves user-facing design changes, please provide a mockup first so we
can all get on the same page. As always, when in doubt, ask!

### How to contribute

1. [Fork the project](https://docs.dev.to/getting-started/forking/) and clone it
   to your local machine. Follow the initial setup
   [here](https://docs.dev.to/installation/).
2. Create a branch with your GitHub username as a prefix and the ID of the
   [issue](https://github.com/thepracticaldev/dev.to/issues) as a suffix, for
   example: `git checkout -b USERNAME/that-new-feature-1234` or
   `git checkout -b USERNAME/fixing-that-bug-1234` where `USERNAME` should be
   replaced by your username and `1234` is the ID of the issue tied to your pull
   request. If there is no issue, you can leave the number out.
3. Code and commit your changes. Bonus points if you write a
   [good commit message](https://chris.beams.io/posts/git-commit/):
   `git commit -m 'Add some feature'`.
4. Push to the branch: `git push -u origin USERNAME/that-new-feature-1234`.
5. [Create a pull request](https://docs.dev.to/getting-started/pull-request/)
   for your branch. 🎉

## Contribution guidelines

### Create an issue

Nobody's perfect. Something doesn't work? Something could be done better? Check
to see if the issue already exists, and if it does, leave a comment to get our
attention! If the issue doesn't already exist, feel free to create a new one. A
core team member will triage incoming issues.

_Please note: core team members may update the title of an issue to more
accurately reflect the request/bug._

### Please include tests

Some existing code may be poorly written or untested, so we must have more
scrutiny going forward. We test with [RSpec](http://rspec.info/).

### Code quality

We use [CodeClimate](https://codeclimate.com/) to evaluate code smells. If a
pull request contributes a significant number of code smells, you may be asked
to refactor your change before it is merged. Focusing on writing reasonably DRY
code with a focus on readability will help avoid unnecessary code smells.

More importantly, we also try to avoid
[wrong abstractions](https://www.sandimetz.com/blog/2016/1/20/the-wrong-abstraction).
Code quality tools are not perfect, so try not to obsess over your CodeClimate
score.

### Create a pull request

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

_Please note: a core team member may close your PR if it has gone stale or if we
don't plan to merge the code._

### Pull requests reviews and "force pushing"

After you submit your pull request (PR), one of the members of the core team or
core contributors will likely do a review of the code accepting it or giving
feedback.

If feedback or suggestions are provided, any changes on your part should happen
in separate commits added to the existing ones.

Force pushing, though understandable for reasons of wanting to keep the history
clean has some drawbacks:

- it removes the review history of the code
- forces the reviewer to start from scratch when adding possible further
  comments

PRs will be squashed and merged into master, so there's no need to use force
push.

Please avoid force pushing unless you need to rebase with the master branch.

## The bottom line

We are all humans trying to work together to improve the community. Always be
kind and appreciate the need for tradeoffs. ❤️
