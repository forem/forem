---
title: End to End Tests
---

# End to End Tests

[Cypress](https://www.cypress.io), a JavaScript based framework, is used for end
to end (E2E) testing. Tests and associated utilities are within the `cypress`
directory.

```shell
$ tree cypress

cypress
├── fixtures
│   ├── images
│   │   └── admin-image.png
│   └── users
│       ├── adminUser.json
│       └── changePasswordUser.json
├── integration
│   ├── adminFlows
│   │   └── config
│   │       └── authenticationSection.spec.js
│   └── loginFlows
│       ├── userChangePassword.spec.js
│       └── userLogin.spec.js
├── plugins
│   └── index.js
└── support
    ├── commands.js
    └── index.js
```

In addition to Cypress, we use
[cypress-testing-library](https://github.com/testing-library/cypress-testing-library).
This provides custom Cypress commands and utilities to improve how E2E tests are
written. dom-testing-library and preact-testing-library are already used for
[front-end tests](/tests/frontend-tests), which both offer a similar API in the
context of testing a Preact or Stimulus component. All these tools are part of
the [Testing Library](https://testing-library.com) family.

For the test web server, the
[cypress-rails](https://github.com/testdouble/cypress-rails) gem is used to
start a test web server that runs a rails test environment (`RAILS_ENV=test`).
It also resets the database between test runs by starting a database transaction
at the beginning of a test and performs a rollback at the end of a test being
run. The cypress-rails gem also provides a rake task that allows us to
coordinate all this work.

## Running E2E Tests Locally

From the command line, run `yarn e2e` to start E2E testing.

1. `bundle check` will run to ensure all the gems for the project are up to
   date. If they are not, you will be prompted to run `bundle install`.

```bash
Doing a quick bundle check to make sure gems are all up to date.

 * zonebie (0.6.1)
Install missing gems with `bundle install`
Unable to launch end to end tests. Ensure that all your gems are installed and up to date.
```

2. `yarn install` will run to ensure front-end packages are up to date.

```bash
[1/5] 🔍  Validating package.json...
[2/5] 🔍  Resolving packages...
success Already up-to-date.
```

3. You will be prompted to set up the end to end (E2E) test database. Type `y`
   or `Y` to install the E2E test database. Typically you only need to select
   `y` the first time you run e2e tests, but it can also be run if ever you
   corrupt your database and need to reset it back to its original state.

```bash
Do you need to set up your end to end (E2E) testing database? Answer yes
if this is your first time running E2E tests on your local machine or you
need to recreate your E2E test database. (y/n)
```

4. If `y` or `Y` is pressed, the E2E test database will install.

```bash
Setting up the E2E database before running E2E tests...


Dropped database 'PracticalDeveloper_test'
Created database 'PracticalDeveloper_test'

...
```

5. The
   [Cypress test runner](https://docs.cypress.io/guides/core-concepts/test-runner.html#Overview)
   will open and you are now ready to run end to end tests.

![A screenshot of the Cypress test runner](/cypress-test-runner.png)

## E2E Tests on CI/CD

E2E tests run on a dedicated build node on Travis. It runs headless via the
`bin/e2e-ci` command. These tests currently do not run in parallel with Knapsack
Pro as there were issues integrating the cypress-rails gem with the
[knapsack-pro-cypress](https://github.com/KnapsackPro/knapsack-pro-cypress) npm
package.

## Cypress Custom commands

[Cypress custom commands](https://docs.cypress.io/api/cypress-api/custom-commands.html)
allow you to extend the functionality of the E2E testing framework. In the case
of Forem, we need custom commands to create an article, for example.

A custom command is prefixed like any Cypress command by `cy.` All custom
commands can be found in the
[commands.js](https://github.com/forem/forem/blob/master/cypress/support/commands.js)
file.

### Creating a Custom Article Command

To create an article as part of your test's setup, use the `cy.createArticle`
custom command. It can be called like so:

```javascript
cy.createArticle({
  title: 'Test Article',
  tags: ['beginner', 'discuss'], // tags are optional
  content: 'This is a test article',
});
```

If you want to do something with the article creation's response, you can call
it like so.

```javascript
cy.createArticle({
  title: 'Test Article',
  tags: ['beginner', 'discuss'], // tags are optional
  content: 'This is a test article',
}).then((response) => {
  cy.visit(response.body.current_state_path); // path to article
});
```

### Creating a Response Template Command

To create a response template as part of your test's setup, use the
`cy.createResponseTemplate` custom command. It can be called like so:

```javascript
cy.createResponseTemplate({
  title: 'Test Canned Response',
  content: 'This is a test canned response',
});
```

## Additional Resources

- [Cypress documentation](https://docs.cypress.io)
- [Making your UI tests resilient to change](https://kentcdodds.com/blog/making-your-ui-tests-resilient-to-change)
  by [Kent C. Dodds](https://twitter.com/kentcdodds)
- [Static vs Unit vs Integration vs E2E Testing for Frontend Apps](https://kentcdodds.com/blog/unit-vs-integration-vs-e2e-tests)
  by Kent C. Dodds
