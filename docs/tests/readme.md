---
title: Test / Coverage / Q&A Guide
items:
  - acceptance-tests.md
  - integration-tests.md
  - unit-tests.md
  - preact-tests.md
  - codeclimate.md
  - simplecov.md
  - skip-ci
---

We use the following testing tools:

- [**RSpec**](http://rspec.info/) for testing the backend
- [**Capybara**](https://github.com/teamcapybara/capybara) with [**selenium-webdriver**](https://github.com/SeleniumHQ/selenium/tree/master/javascript/node/selenium-webdriver) for view testing
- [**webdrivers**](https://github.com/titusfortner/webdrivers) for standard JS testing
- [**guard-rspec**](https://github.com/guard/guard-rspec) for automated testing
- [**Jest**](https://facebook.github.io/jest) for testing in the front-end
- [**preact-render-spy**](https://github.com/mzgoddard/preact-render-spy) for testing Preact components.
- [**SimpleCov**](https://github.com/colszowka/simplecov) for tracking overall test coverage

Each pull request should come with tests related to the newly written feature or bug fix. Ideally, we should test both the front end and back end.

If you'd like to help us improve our test coverage, we recommend checking out our total coverage and writing tests for selected files based on SimpleCov's (more below) test coverage results.

If you're new to writing tests in general or with Rails, we recommend reading about testing with Rails, RSpec, and Capybara first.

## Continuous Integration & Continuous Deployment

We are using Travis for CI and CD. Travis will run a build (in isolated environment for testing) for every push to this repository. Keep in mind that a passing-build does not necessarily mean the project won't run into any issues. Strive to write good tests for any chunk of code you wish to contribute. Travis will deploy a pull request to production after CI passes. Our test suite is not perfect and sometimes a re-rerun is needed.
