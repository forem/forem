<p align="center">
  <a href="https://www.algolia.com">
      <img alt="Algolia for Ruby" src="https://raw.githubusercontent.com/algolia/algoliasearch-client-common/master/banners/ruby.png" >
    </a>
</p>

Hello and welcome to the contributing guide for algolia gem. Thanks for considering participating in our project 🙇

If this guide does not contain what you are looking for and thus prevents you from contributing, don't hesitate to leave a message on the [community forum](https://discourse.algolia.com/) or to [open an issue](https://github.com/algolia/algoliasearch-client-ruby/issues).

<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN TocDown TO UPDATE -->
<!-- TocDown Begin -->
* [Reporting an issue](#reporting-an-issue)
* [The code contribution process](#the-code-contribution-process)
* [Commit conventions](#commit-conventions)
* [Branch organization](#branch-organization)
* [Requirements](#requirements)
* [Code structure](#code-structure)
  * [The source algolia folder](#the-source-algolia-folder)
* [Tests](#tests)
* [Linting](#linting)
<!-- TocDown End -->

## Reporting an issue

Opening an issue is very effective way to contribute because other users might also be impacted. We'll make sure to fix it quickly if it's technically feasible and doesn't have important side effects for other users.

Before reporting an issue, first check that there is not an already open issue for the same topic using the [issues page](https://github.com/algolia/algoliasearch-client-ruby/issues). Don't hesitate to thumb up an issue that corresponds to the problem you have.

It would be very helpful if you're able to add a test case that reproduces the issue. This could help us solve the issue faster.

## The code contribution process

The algolia gem is developed in Ruby ≥ 2.2.

For any code contribution, you need to:

- Fork and clone the project
- Create a new branch for what you want to solve (fix/_issue-number_, feat/_name-of-the-feature_)
- Make your changes
- Open a pull request

Depending on what you're working on, you might consider different [base branches](#branch-organization).

Then:

- Peer review of the pull request (by at least one of the core contributors)
- Automatic checks ([tests](#tests), [commits](#commit-conventions), [linters](#linting))
- When everything is green, one of the core contributors will merge your contribution 🚀

## Commit conventions

This project follows the [conventional changelog](https://conventionalcommits.org/) approach. This means that all commit messages should be formatted using the following scheme:

```
type(scope): description
```

In most cases, we use the following types:

- `fix`: for any resolution of an issue (identified or not)
- `feat`: for any new feature
- `refactor`: for any code change that neither adds a feature nor fixes an issue
- `docs`: for any documentation change or addition
- `chore`: for anything that is not related to the library itself (doc, tooling)

Even though the scope is optional, we try to fill it in as it helps us better understand the impact of a change. We either use the name of the widget/connector/component impacted or we use impact topic (e.g. `docs`, `tooling`, `deps`, `ci`).

Finally, if your work is based on an issue on GitHub, please fill in the dedicated line in the PR template (read "[Closing issues using keywords](https://help.github.com/en/articles/closing-issues-using-keywords)").

Some examples of valid commit messages (used as first lines):

> - feat(account-client): add method XXX
> - chore(deps): update dependency XXX to v3.0.7
> - fix(search_user_ids): rename parameter clusterName
> - chore: reword contributions guides

## Branch organization

The project is based on the classic GitHub flow:

- `master` for the current version being worked on – Pull requests for bugs and feature related to the current major version should be created against this branch
- `vX` for each major version (`X` being a number) – Pull requests for critical bug fixes should be created against this branch

Most of the time, your pull requests should target the `master` branch.

_Note that no new features will be developed or backported for the `vX` branches._

## Requirements

To run this project, you will need:

- Ruby ≥ 2.2
- [Bundler](https://bundler.io/)

## Use the Dockerfile

If you want to contribute to this project without installing all its dependencies, you can use our Docker image. 
Please check our [dedicated guide](DOCKER_README.MD) to learn more.

## Code structure

Here are the main files and folders of the project

```
▸ lib/algolia/              << standalone clients and helpers classes
▸ lib/test/                 << gathers the unit and integration tests
  .rubocop.yml              << contains the rule used for the linter
  algolia.gemspec           << gemspec file
  CHANGELOG.md              << changelog file
  CONTRIBUTING.md           << this file
  Gemfile                   << dependencies needed to run the project locally
  Rakefile                  << defines the different tasks to lint/test the project
  README.md                 << the introduction of the project
```

### The lib/algolia folder

```
▸ lib/algolia/
    ▸ config/       << the configurations associated with each clients 
    ▸ enums/        << enumerables used accross the lib
    ▸ http/         << the http layer logic
    ▸ iterators/    << the iterators used for the browsing methods
    ▸ responses/    << the waitable responses
    ▸ transport/    << the transport layer logic
```

## Tests

Our unit and integration tests are written with [Minitest](https://github.com/seattlerb/minitest), in the `test` syntax.

To run all the tests at once:

```sh
bundle exec rake test:all
```

To run only the unit tests:

```sh
bundle exec rake test:unit
```

To run only the integration tests:

```sh
bundle exec rake test:integration
```

We ask that for each fix or feature submitted, you add at least one test demonstrating its behaviour. As you will need to use your own Algolia credentials to run them, we advise you to keep them short and use a small dataset, as well as using a mock requester anytime it's possible. If you encounter huge data overload because of testing, please reach out to [our support team](support@algolia.com).

## Linting

Linters help us maintain a consistent code base.

If your editor support them, then you will see the errors directly there. You can also run them using your command line:

```sh
rake rubocop
```

However, we recommend that you use in your workflow pre-commit hooks, to avoid submitting code that might not pass the linting task setup in the CI. To use them,
first download the gem `git-precommit`

```sh
gem install git-precommit
```

Then copy-paste the following content in a file called `pre-commit` in `.git/hooks/` 

```sh
#!/usr/bin/env sh

function unstaged_changes {
    ! git diff --quiet
}

if unstaged_changes; then
    git stash save --keep-index "Performing partial commit against `git rev-parse HEAD`"
fi

exec time bundle exec rake precommit
```
