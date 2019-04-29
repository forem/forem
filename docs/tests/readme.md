---
title: Testing / Q&A Guide
items:
  - acceptance-tests.md
  - integration-tests.md
  - unit-functional-tests.md
  - preact-tests.md
  - code-coverage.md
  - codeclimate.md
  - skip-ci.md
---

We use the following testing tools:

- [**RSpec**](http://rspec.info/) for testing the Rails backend
- [**Capybara**](https://github.com/teamcapybara/capybara) with [**webdrivers**](https://github.com/titusfortner/webdrivers) for acceptance testing
- [**guard-rspec**](https://github.com/guard/guard-rspec) for automated testing
- [**Jest**](https://jestjs.io/) for testing the frontend
- [**preact-render-spy**](https://github.com/mzgoddard/preact-render-spy) for testing Preact components
- [**SimpleCov**](https://github.com/colszowka/simplecov) for tracking overall test coverage on the backend

Each pull request should come with tests related to the newly written feature or bug fix. Ideally, we should test both the frontend and backend.

If you'd like to help us improve our test coverage, we recommend checking out our total coverage and writing tests for selected files based on SimpleCov's test coverage results. You can also check out [Code Climate summary](https://codeclimate.com/github/thepracticaldev/dev.to) which includes the test coverage.

If you're new to writing tests in general or with Rails, we recommend reading about [testing with Rails, RSpec, and Capybara first](https://guides.rubyonrails.org/testing.html).

## Continuous Integration & Continuous Deployment

We are using Travis for CI and CD. Travis will run a build (in an isolated environment for testing) for every push to this repository.

Keep in mind that a passing build does not necessarily mean the project won't run into any issues. Strive to write good tests for the code you wish to contribute.

Travis will deploy your pull request to production after CI passes and a member of the DEV team has approved it.

Our test suite is not perfect and sometimes a re-run is needed.
