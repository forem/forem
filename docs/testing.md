# Testing

We use the following testing tools:

* [**RSpec**](http://rspec.info/) for testing the backend
* [**Capybara**](https://github.com/teamcapybara/capybara) with [**selenium-webdriver**](https://github.com/SeleniumHQ/selenium/tree/master/javascript/node/selenium-webdriver) for view testing
* [**chromedriver-helper**](https://github.com/flavorjones/chromedriver-helper) for standard JS testing
* [**guard-rspec**](https://github.com/guard/guard-rspec) for automated testing
* [**Jest**](https://facebook.github.io/jest) for testing in the front-end
* [**SimpleCov**](https://github.com/colszowka/simplecov) for tracking overall test coverage

Each pull request should come with tests related to the newly written feature or bug fix. Ideally, we should test both the front end and back end.

If you'd like to help us improve our test coverage, we recommend checking out our total coverage and writing tests for selected files based on SimpleCov's (more below) test coverage results.

If you're new to writing tests in general or with Rails, we recommend reading about testing with Rails, RSpec, and Capybara first.

## How to Use SimpleCov

1.  Run `bundle exec rspec spec` or `bin/rspec spec`. You can run RSpec on the whole project or a single file.
2.  After rspec is complete, open `index.html` within the coverage folder to view code coverages.

You can also run `bin/rspecov` to run `bin/rspec spec`

## CodeClimate

We are using CodeClimate to track code quality and code coverage. Codeclimate will grade the quality of the code of every PR but not the entirety of the project. If you feel that the current linting rule is unreasonable, feel free to submit a _separate_ PR to change it. Fix any errors that CodeClimate provides and strive to leave code better than you found it.

Travis will upload Simplecov data to CodeClimate. We are still in the early stage of using it so it may not provide an accurate measurement our of codebase.

#### Skipping CI build (Not recommended)

If your changes are **minor** (i.e. updating README, fixing a typo), you can skip CI by adding `[ci skip]` to your commit message.

## Continuous Integration & Continuous Deployment

We are using Travis for CI and CD. Travis will run a build (in isolated environment for testing) for every push to this repository. Keep in mind that a passing-build does not necessarily mean the project won't run into any issues. Strive to write good tests for any chunk of code you wish to contribute. Travis will deploy a pull request to production after CI passes. Our test suite is not perfect and sometimes a re-rerun is needed.
