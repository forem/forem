<!---
This file was generated on 2020-12-25T18:48:30+00:00 from the rspec-dev repo.
DO NOT modify it by hand as your changes will get lost the next time it is generated.
-->

# The CI build, in detail

The [Travis CI build](https://travis-ci.org/rspec/rspec-mocks)
runs many verification steps to prevent regressions and
ensure high-quality code. To run the Travis build locally, run:

```
$ script/run_build
```

It can be useful to run the build steps individually
to repro a failing part of a Travis build. Let's break
the build down into the individual steps.

## Specs

RSpec dogfoods itself. Its primary defense against regressions is its spec suite. Run with:

```
$ bundle exec rspec

# or, if you installed your bundle with `--standalone --binstubs`:

$ bin/rspec
```

The spec suite performs a couple extra checks that are worth noting:

* *That all the code is warning-free.* Any individual example that produces output
  to `stderr` will fail. We also have a spec that loads all the `lib` and `spec`
  files in a newly spawned process to detect load-time warnings and fail if there
  are any. RSpec must be warning-free so that users who enable Ruby warnings will
  not get warnings from our code.
* *That only a minimal set of stdlibs are loaded.* Since Ruby makes loaded libraries
  available for use in any context, we want to minimize how many bits of the standard
  library we load and use. Otherwise, RSpec's use of part of the standard library could
  mask a problem where a gem author forgets to load a part of the standard library they
  rely on. The spec suite contains a spec that defines a list of allowed loaded
  stdlibs.

In addition, we use [SimpleCov](https://github.com/colszowka/simplecov)
to measure and enforce test coverage. If the coverage falls below a
project-specific threshold, the build will fail.

## Cukes

RSpec uses [cucumber](https://cucumber.io/) for both acceptance testing
and [documentation](https://relishapp.com/rspec). Since we publish our cukes
as documentation, please limit new cucumber scenarios to user-facing examples
that help demonstrate usage. Any tests that exist purely to prevent regressions
should be written as specs, even if they are written in an acceptance style.
Duplication between our YARD API docs and the cucumber documentation is fine.

Run with:

```
$ bundle exec cucumber

# or, if you installed your bundle with `--standalone --binstubs`:

$ bin/cucumber
```

## YARD documentation

RSpec uses [YARD](https://yardoc.org/) for API documentation on the [rspec.info site](https://rspec.info/).
Our commitment to [SemVer](https://semver.org) requires that we explicitly
declare our public API, and our build uses YARD to ensure that every
class, module and method has either been labeled `@private` or has at
least some level of documentation. For new APIs, this forces us to make
an intentional decision about whether or not it should be part of
RSpec's public API or not.

To run the YARD documentation coverage check, run:

```
$ bundle exec yard stats --list-undoc

# or, if you installed your bundle with `--standalone --binstubs`:

$ bin/yard stats --list-undoc
```

We also want to prevent YARD errors or warnings when actually generating
the docs. To check for those, run:

```
$ bundle exec yard doc --no-cache

# or, if you installed your bundle with `--standalone --binstubs`:

$ bin/yard doc --no-cache
```

## RuboCop

We use [RuboCop](https://github.com/rubocop-hq/rubocop) to enforce style
conventions on the project so that the code has stylistic consistency
throughout. Run with:

```
$ bundle exec rubocop lib

# or, if you installed your bundle with `--standalone --binstubs`:

$ bin/rubocop lib
```

Our RuboCop configuration is a work-in-progress, so if you get a failure
due to a RuboCop default, feel free to ask about changing the
configuration. Otherwise, you'll need to address the RuboCop failure,
or, as a measure of last resort, by wrapping the offending code in
comments like `# rubocop:disable SomeCheck` and `# rubocop:enable SomeCheck`.

## Run spec files one-by-one

A fast TDD cycle depends upon being able to run a single spec file,
without the rest of the test suite. While rare, it's fairly easy to
create a situation where a spec passes when the entire suite runs
but fails when its individual file is run. To guard against this,
our CI build runs each spec file individually, using a bit of bash like:

```
for file in `find spec -iname '*_spec.rb'`; do
  echo "Running $file"
  bin/rspec $file -b --format progress
done
```

Since this step boots RSpec so many times, it runs much, much
faster when we can avoid the overhead of bundler. This is a main reason our
CI build installs the bundle with `--standalone --binstubs` and
runs RSpec via `bin/rspec` rather than `bundle exec rspec`.

## Running the spec suite for each of the other repos

While each of the RSpec repos is an independent gem (generally designed
to be usable on its own), there are interdependencies between the gems,
and the specs for each tend to use features from the other gems. We
don't want to merge a pull request for one repo that might break the
build for another repo, so our CI build includes a spec that runs the
spec suite of each of the _other_ project repos. Note that we only run
the spec suite, not the full build, of the other projects, as the spec
suite runs very quickly compared to the full build.
