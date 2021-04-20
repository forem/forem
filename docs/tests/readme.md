---
title: Testing/QA Guide
items:
  - acceptance-tests.md
  - integration-tests.md
  - unit-functional-tests.md
  - frontend-tests.md
  - manual-tests.md
  - accessibility-tests.md
  - e2e-tests.md
  - regression-tests.md
  - code-coverage.md
  - codeclimate.md
  - test-flags.md
---

We use the following testing tools:

- [**RSpec**](http://rspec.info/) for testing the Rails backend
- [**Capybara**](https://github.com/teamcapybara/capybara) with
  [**webdrivers**](https://github.com/titusfortner/webdrivers) for acceptance
  testing
- [**guard-rspec**](https://github.com/guard/guard-rspec) for automated testing
- [**Jest**](https://jestjs.io/) for testing the frontend
- [**jest-axe**](https://github.com/nickcolley/jest-axe) for detecting basic
  a11y regressions
- [**preact-testing-library**](https://github.com/testing-library/preact-testing-library)
  for testing Preact components
- [**SimpleCov**](https://github.com/colszowka/simplecov) for tracking overall
  test coverage on the backend

We strive to provide tests for each pull request that adds new features or fixes
a bug. Ideally, we test the functionality of the frontend and the backend.

If you'd like to help us improve our test coverage, we recommend checking out
our total coverage and writing tests for selected files based on SimpleCov's
test coverage results. You can also check out
[Code Climate summary](https://codeclimate.com/github/forem/forem) which
includes the test coverage.

If you're new to writing tests in general or with Rails, we recommend reading
about
[testing with Rails, RSpec, and Capybara first](https://guides.rubyonrails.org/testing.html).

## Continuous Integration & Continuous Deployment

We are using Travis for CI and CD. Travis will run a build (in an isolated
environment for testing) for every push to this repository. We also recently
added [KnapsackPro](https://knapsackpro.com/) to our Travis CI setup.
KnapsackPro allows us to split up our tests evenly between 3 different
jobs(virtual machines). These 3 jobs all run in parallel which helps decrease
the time needed to run all of our specs.

If you want more information about your CI job or how long specific specs take
to run you can find all of that information on our
[KnapsackPro public dashboard](https://knapsackpro.com/dashboard/organizations/1142/projects/1022/test_suites/1434/builds).

Keep in mind that a passing build does not necessarily mean the project won't
run into any issues. Strive to write good tests for the code you wish to
contribute.

Travis will deploy your pull request to production after CI passes and a member
of the Forem team has approved it.

Our test suite is not perfect and sometimes a re-run is needed. If you encounter
a "flaky spec" that fails intermittently please open an issue so we can address
it. In order to get your test suite to pass after a flaky spec has failed simply
retry the individual job that failed rather than the entire suite in order to
save some time. When you retry the individual job, make sure to also retry the
Deploy job. Even though you may not be deploying that job must complete for the
entire build to pass.

Please note that you will need to have Elasticsearch installed and running for
certain tests in our test suite. You can find instructions on how to install and
run Elasticsearch specific to your environment in the
[Installation Guide](/installation).
