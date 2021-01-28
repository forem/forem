---
title: Contributing to Forem
---

# Contributing to Forem

We expect contributors to abide by our underlying
[Code of Conduct](https://dev.to/code-of-conduct). All discussions about this
project must be respectful and harassment-free.

Remember that communication is the lifeblood of any Open Source project. We are
all working on this together, and we are all benefiting from this software.

It's very easy to misunderstand one another in asynchronous, text-based
conversations. When in doubt, assume everyone has the best intentions.

If you feel anyone has violated our Code of Conduct, you should anonymously
contact the team with our [abuse report form](https://dev.to/report-abuse).

### Where to contribute

All [issues](https://github.com/forem/forem/issues) labeled
[ready for dev](https://github.com/forem/forem/issues?q=is%3Aissue+is%3Aopen+label%3A%22ready+for+dev%22)
and
[bug](https://github.com/forem/forem/issues?q=is%3Aissue+is%3Aopen+label%3A%22type%3A+bug%22+label%3Abug)
are up for grabs.

\*\*Please note that issues with the
[Forem team](https://github.com/forem/forem/labels/Forem%20team) label are
internal tasks that will be completed by a Forem
[core team member](https://github.com/forem/forem/#core-team).

- [good first issue](https://github.com/forem/forem/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22+)
  issues are meant for newer developers.
- [difficulty: easy](https://github.com/forem/forem/issues?q=is%3Aopen+is%3Aissue+label%3A%22difficulty%3A+easy%22)
  issues are usually confined to isolated areas of existing code.
- [difficulty: medium](https://github.com/forem/forem/issues?q=is%3Aopen+is%3Aissue+label%3A%22difficulty%3A+medium%22)
  issues sometimes entail new features and might affect a significant area of
  the codebase, but aren't overly complex.
- [difficulty: hard](https://github.com/forem/forem/issues?q=is%3Aopen+is%3Aissue+label%3A%22difficulty%3A+hard%22)
  issues are typically far-reaching, and might need architecture decisions
  during implementation. This label might also denote highly complex issues.

PRs without an associated issue may still be merged, but the core team will
focus on changes that solve existing issues. We strongly encourage creating an
issue before working on a PR!

When in doubt, ask a
[core team member](https://github.com/forem/forem/#core-team) by mentioning us
on the issue.

**Documentation** is almost always a great place to start contributing to a new
project. Forem is an Open Source, community-driven project. Therefore, providing
and maintaining quality documentation is one of our most important jobs. You can
find more information in our
[docs guide](https://docs.forem.com/contributing/docs)!

**Refactoring**, which involves improving the code without modifying behavior,
is a great place to help out! Generally speaking, you can rely on existing tests
to ensure that your refactor doesn't introduce any unexpected behavior. If an
area isn't well tested, you might be asked to include a regression test with
your refactoring PR. Refactors can touch many files, so we encourage breaking
big changes into small PRs.

**Fixing bugs** is a super fast way to improve the experience for our users!
When you're fixing bugs, we appreciate communication in a GitHub issue. If an
issue exists, please claim that issue and link it in your PR, otherwise creating
an issue is the best first step! Be sure to surround bug fixes with ample tests;
bugs are magnets for other bugs. Write tests around bugs!

**Features** tend to be subjective and might spur some debate. The Forem core
team uses an internal RFC ("request for comments") process to assess and
prioritize new features. This process is intended to provide a consistent and
standardized path for new changes to enter the Forem ecosystem. If you'd like to
propose a new feature, please visit [forem.dev](https://forem.dev) to start a
discussion around a new feature (or chime in on a pre-existing discussion!).

There may be some open issues in our repository that we think evolve into
impactful features. For such issues, we use the
[potential RFC](https://github.com/forem/forem/labels/potential%20RFC) label in
order to highlight the potential feature to the Forem core team members so that
someone from the team can champion that feature.

You can learn more about our internal RFC process and how we use forem.dev
[here](https://forem.dev/foremteam/internal-rfc-process-and-forem-dev-discussions-3gl4)

### How to contribute

1. [Fork the project](https://docs.forem.com/getting-started/forking/) and clone
   it to your local machine. Follow the
   [installation guide](https://docs.forem.com/installation/)!
2. Create a branch with your GitHub username and the ID of the
   [issue](https://github.com/forem/forem/issues), for example:
   `git checkout -b USERNAME/some-new-feature-1234`
3. Code and commit your changes. Bonus points if you write a
   [good commit message](https://chris.beams.io/posts/git-commit/):
   `git commit -m 'Add some feature'`
4. Push to the branch: `git push -u origin USERNAME/some-new-feature-1234`
5. [Create a pull request](https://docs.forem.com/getting-started/pull-request/)
   for your branch. 🎉

## Contribution guidelines

### Create an issue

Nobody's perfect. Something doesn't work? Something could be better? Check to
see if the issue already exists, and if it does, leave a comment to get our
attention! If the issue doesn't already exist, feel free to create a new one. A
core team member will triage incoming issues.

_Please note: core team members may update the title of an issue to reflect the
discussion._

### Please include tests

Some areas of the project could use updated tests, and new features should
always include test coverage. Please give our
[testing guide](https://docs.forem.com/tests/) a read!

### Code quality

We use [Code Climate](https://codeclimate.com/) to find code smells. If a pull
request contains code smells, we might recommend a refactor before merging. We
like readable code, and encourage DRY when it's reasonable!

More importantly, we avoid
[wrong abstractions](https://www.sandimetz.com/blog/2016/1/20/the-wrong-abstraction).
Code quality tools are not perfect, so don't obsess over your Code Climate
score.

### Consider accessibility in UI changes

If the change you're proposing touches a user interface, include accessibility
in your approach. This includes things like color contrast, keyboard
accessibility, screen reader labels, and other common requirements. For more
information, check out the
[Forem Accessibility docs page](https://docs.forem.com/frontend/accessibility).

### Please use inclusive language

Inclusion and respect are core tenets of our
[Code of Conduct](https://dev.to/code-of-conduct). We expect thoughtful language
all the way down to the code. Some technical metaphors are alienating or
triggering. We ask that contributors go the extra mile to submit code which is
inclusive in nature.

If you unintentionally use language deemed harmful, there is no shame. We will
work together to find a better alternative. Being thoughtful about language also
encourages more thoughtful code!

### Create a pull request

- Try to keep the pull requests small. A pull request should try its very best
  to address only a single concern.
- For work in progress pull requests, please use the
  [Draft PR](https://github.blog/2019-02-14-introducing-draft-pull-requests/)
  feature.
- Make sure all tests pass and add additional tests for the code you submit.
  [More info here](https://docs.forem.com/tests/).
- Document your reasoning behind the changes. Explain why you wrote the code in
  the way you did. The code should explain what it does.
- If there's an existing issue, reference to it by adding something like
  `References/Closes/Fixes/Resolves #123`, where 123 is the issue number.
  [More info here](https://github.com/blog/1506-closing-issues-via-pull-requests).
- Please fill out the PR Template when making a PR.
- All commits in a pull request will be squashed when merged.

_Please note: a core team member may close your PR if it has gone stale or if we
don't plan to merge the code._

### Pull request reviews

All community pull requests are reviewed by our core team.

- All contributors must sign the CLA.
- All required checks are expected to pass on each PR.
  - In the case of flaky or unrelated test failures, a core team member will
    restart CI.
- We require 2 approvals from core team members for each PR.
- Requested Changes must be resolved (with code or discussion) before merging.
- If you make changes to a PR, be sure to re-request a review.
- Style discussions are generally discouraged in PR reviews; make a PR to the
  linter configurations instead.
- Your code will be deployed shortly after it is merged.

### A note on "force pushing"

After you submit your pull request, one of the members of the core team will
review your code.

Please avoid force pushing unless you need to rebase with the master branch.

If feedback is provided, any changes should be contained in new commits. Please
don't force push or worry about squashing your commits.

Force pushing (despite being useful) has some drawbacks. GitHub doesn't always
keep the review history, which results in lost context for the reviewers.

We squash every PR before merging, so there is no need to force push!

## The bottom line

We are all humans trying to work together to improve the community. Always be
kind and appreciate the need for tradeoffs. ❤️
