<!---
This file was generated on 2020-12-25T18:48:30+00:00 from the rspec-dev repo.
DO NOT modify it by hand as your changes will get lost the next time it is generated.
-->

# Development Setup

Generally speaking, you only need to clone the project and install
the dependencies with [Bundler](https://bundler.io/). You can either
get a full RSpec development environment using
[rspec-dev](https://github.com/rspec/rspec-dev#README) or you can
set this project up individually.

## Setting up rspec-core individually

For most contributors, setting up the project individually will be simpler.
Unless you have a specific reason to use rspec-dev, we recommend using this approach.

Clone the repo:

```
$ git clone git@github.com:rspec/rspec-core.git
```

Install the dependencies using [Bundler](https://bundler.io/):

```
$ cd rspec-core
$ bundle install
```

To minimize boot time and to ensure we don't depend upon any extra dependencies
loaded by Bundler, our CI builds avoid loading Bundler at runtime
by using Bundler's [`--standalone option`](https://myronmars.to/n/dev-blog/2012/03/faster-test-boot-times-with-bundler-standalone).
While not strictly necessary (many/most of our contributors do not do this!),
if you want to exactly reproduce our CI builds you'll want to do the same:

```
$ bundle install --standalone --binstubs
```

The `--binstubs` option creates the `bin/rspec` file that, like `bundle exec rspec`, will load
all the versions specified in `Gemfile.lock` without loading bundler at runtime!

## Using rspec-dev

See the [rspec-dev README](https://github.com/rspec/rspec-dev#README)
for setup instructions.

The rspec-dev project contains many rake tasks for helping manage
an RSpec development environment, making it easy to do things like:

* Change branches across all repos
* Update all repos with the latest code from `main`
* Cut a new release across all repos
* Push out updated build scripts to all repos

These sorts of tasks are essential for the RSpec maintainers but will
probably be unnecessary complexity if you're just contributing to one
repository. If you are getting setup to make your first contribution,
we recommend you take the simpler route of setting up rspec-core
individually.

## Gotcha: Version mismatch from sibling repos

The [Gemfile](Gemfile) is designed to be flexible and support using
the other RSpec repositories either from a local sibling directory
(e.g. `../rspec-<subproject>`) or, if there is no such directory,
directly from git. This generally does the "right thing", but can
be a gotcha in some situations. For example, if you are setting up
`rspec-core`, and you happen to have an old clone of `rspec-expectations`
in a sibling directory, it'll be used even though it might be months or
years out of date, which can cause confusing failures.

To avoid this problem, you can either `export USE_GIT_REPOS=1` to force
the use of `:git` dependencies instead of local dependencies, or update
the code in the sibling directory. rspec-dev contains rake tasks to
help you keep all repos in sync.

## Extra Gems

If you need additional gems for any tasks---such as `benchmark-ips` for benchmarking
or `byebug` for debugging---you can create a `Gemfile-custom` file containing those
gem declarations. The `Gemfile` evaluates that file if it exists, and it is git-ignored.

# Running the build

The [Travis CI build](https://travis-ci.org/rspec/rspec-core)
runs many verification steps to prevent regressions and
ensure high-quality code. To run the Travis build locally, run:

```
$ script/run_build
```

See [build detail](BUILD_DETAIL.md) for more detail.

# What to Expect

To ensure high, uniform code quality, all code changes (including
changes from the maintainers!) are subject to a pull request code
review. We'll often ask for clarification or suggest alternate ways
to do things. Our code reviews are intended to be a two-way
conversation.

Here's a short, non-exhaustive checklist of things we typically ask contributors to do before PRs are ready to merge. It can help get your PR merged faster if you do these in advance!

- [ ] New behavior is covered by tests and all tests are passing.
- [ ] No Ruby warnings are issued by your changes.
- [ ] Documentation reflects changes and renders as intended.
- [ ] RuboCop passes (e.g. `bundle exec rubocop lib`).
- [ ] Commits are squashed into a reasonable number of logical changesets that tell an easy-to-follow story.
- [ ] No changelog entry is necessary (we'll add it as part of the merge process!)

# Adding Docs

RSpec uses [YARD](https://yardoc.org/) for its API documentation. To
ensure the docs render well, we recommend running a YARD server and
viewing your edits in a browser.

To run a YARD server:

```
$ bundle exec yard server --reload

# or, if you installed your bundle with `--standalone --binstubs`:

$ bin/yard server --reload
```

Then navigate to `localhost:8808` to view the rendered docs.
