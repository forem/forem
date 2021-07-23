---
title: End to End Tests
---

# End to End Tests

We use [Cypress](https://www.cypress.io), a JavaScript based framework, for end
to end (E2E) testing. You can find tests and associated utilities in the
`cypress` directory:

```
cypress
├── fixtures (Any hard-coded data, e.g. test users, images)
├── integration (The actual tests, grouped by user flow)
├── plugins (Cypress plugins)
└── support (Where custom commands are found and added)
```

## Additional tools used

We enhance our use of Cypress with a couple of additional packages.

### cypress-testing-library

We use
[cypress-testing-library](https://github.com/testing-library/cypress-testing-library)
for custom Cypress commands and utilities to improve how we write our tests.
This package is part of the [Testing Library](https://testing-library.com)
family that we also use in [front-end tests](/tests/frontend-tests), offering a
similar API.

### cypress-rails

We use the [cypress-rails](https://github.com/testdouble/cypress-rails) gem to
start a test web server that runs a rails test environment (`RAILS_ENV=test`).

It also resets the database between test runs by starting a database transaction
at the beginning of a test and performs a rollback at the end of a test being
run. The cypress-rails gem also provides a rake task that allows us to
coordinate all this work.

## How to run E2E tests locally

### 1. From the command line, run `yarn e2e`

Note: If you want to run E2E tests that do not require seeded data, run
`yarn e2e:noseed`. Some tests, like the admin onboarding require there to be no
seeded data.

Some initial setup and checks will automatically run as part of this command:

- `bundle check`: You will be prompted to run `bundle install` if gems for the
  project are not up to date.
- `yarn install`: will ensure front-end packages are up to date.

### 2. You will then be prompted to set up the end to end (E2E) test database

```
Do you need to set up your end to end (E2E) testing database?

Answer yes if this is your first time running E2E tests on your local machine or you need to recreate your E2E test database. (y/n)
```

Type `y` if you need to install the E2E test database. Typically you only need
to do this the first time you run e2e tests, but you can also run it if:

- you have added additional seed data to `seeds_e2e.rb`
- your data based might be corrupted and you want to reset it back to its
  original state

### 3. Ready to run tests!

The
[Cypress test runner](https://docs.cypress.io/guides/core-concepts/test-runner.html#Overview)
will open and you are now ready to run end to end tests.

While the test runner is open, any new or updated tests will be dynamically
reflected in the UI.

![A screenshot of the Cypress test runner](/cypress-test-runner.png)

## E2E Tests on CI/CD

E2E tests automatically run on a dedicated build node on Travis. It runs
headless via the `bin/e2e-ci` command. These tests currently do not run in
parallel with Knapsack Pro as there were issues integrating the cypress-rails
gem with the
[knapsack-pro-cypress](https://github.com/KnapsackPro/knapsack-pro-cypress) npm
package.

## Writing Cypress tests

### Seed data

When the E2E test database is set up (via the `yarn e2e` command), it is seeded
with the data in
[`spec/support/seeds/seeds_e2e.rb`.](https://github.com/forem/forem/blob/816855ce3b1c49eaa38f65c63878b33228b1ee9f/spec/support/seeds/seeds_e2e.rb)

This seeds file can be added to as needed, and the new data will be reflected
when you next run `yarn e2e` and select `y` to the question "Do you need to set
up your end to end (E2E) testing database?".

### Test setup

Any individual test setup steps can be included in the `beforeEach` hook. You
will almost always want to call the
[custom Cypress command](https://docs.cypress.io/api/cypress-api/custom-commands.html):

```js
cy.testSetup();
```

This makes sure that previous cookies are cleared, and the Rails database state
is reset (e.g. clearing any articles or changes made in previous tests).

Some other useful custom commands for setting up tests include:

- **`cy.loginAndVisit(user, url)`**: Logs in the given user and navigates to the
  URL, waiting for any user login side effects to complete.
- **`cy.loginUser(user)`**: Logs in the given user, without routing to any page.
  This is handy if you need to complete any other setup steps before visiting
  the page under test.
- **`cy.createArticle(articleData)`**: Creates an article for the currently
  logged in user. The response returns the URL path to the new article, e.g:
  `response.body.current_state_path`
- **`cy.visitAndWaitForUserSideEffects(url)`**: Visits the given page and waits
  for any user related network requests to complete to make sure the UI is in a
  'ready' state for testing. Particularly useful if you couldn't use
  `cy.loginAndVisit`.
- **`cy.signOutUser()`**: Logs out the current user and returns to the home
  page, waiting on any side effects completing.

You can
[see all custom commands in the Cypress support.commands.js file](https://github.com/forem/forem/blob/d21a5d8ed4501d19c4f499013081b212cc8dd97f/cypress/support/commands.js)

### Finding elements

In almost all cases, we use
[cypress-testing-library](https://github.com/testing-library/cypress-testing-library)
commands to find elements in tests.

The most robust way to do this is to find by role and accessible name, e.g.:

```js
cy.findByRole('button', { name: 'Log in' });
```

We favor `findByRole` queries where possible because:

- It is more specific and reliable than e.g. `cy.findByText('Log in')` -
  narrowing our selector to only buttons helps us make sure we match with the
  correct element.
- It will only return accessible elements. For example, any element with
  `display: none` or similar property that would stop a user from perceiving or
  interacting with the element will not be returned.
- It draws attention to problematic HTML that could impact users of assistive
  technology. For example, if the "Log in" button was actually a `div`, it won't
  be returned by the above selector.
- It can help highlight issues with accessible names. For example, if
  `cy.findByRole('link', { name: 'Profile' })` returns 10 links for different
  profiles, we can readily identify an accessiblity issue where screen reader
  users would not be able to differentiate between the links.

#### Scoping selectors

Cypress allows for a few methods to scope our element selectors to specific
sections of the page. Scoping to a smaller area of the page can allow us to
select elements more easily, and focus in on the area of the app under test.

##### Chaining

One way to scope your selector is to chain it off of a previous selector. For
example, the below code will find the article link contained within the `<main>`
element, ignoring any similar links the header, etc:

```js
cy.findByRole('main').findByRole('link', { name: 'My article' });
```

This is particularly useful if you only need to find a single element in the
given section of the page.

##### Using the `within` callback

Another way to scope your selectors is by using the `within` method. This scopes
any selectors in the callback to the given element, and can be particularly
useful if you want to conduct all of your test steps within the same container.

For example, the below code will find the "profile preview" card, and then scope
all queries to that card alone, ignoring any other content on the page:

```js
cy.findByTestId('profile-preview-card').within(() => {
  cy.findByRole('link', { name: 'User profile' });
  cy.findByRole('button', { name: 'Follow' });
});
```

#### Best practice in selecting elements

We tend to follow the
[testing-library guiding principles](https://testing-library.com/docs/guiding-principles)
for selecting elements:

> The more your tests resemble the way your software is used, the more
> confidence they can give you.

You can
[find the suggested priority order of testing-library queries on their website](https://testing-library.com/docs/queries/about#priority),
but as a general rule, we try to favor queries which are accessible to
everyone - i.e. how would a user find a "Log in" button? They'd look for a
button with the name "Log in", so `cy.findByRole('button', { name: 'Log in' })`
seems like a good fit

Avoid selecting elements by classname or any other property that our users
wouldn't be aware of. If you need to find an element that doesn't have an
obvious semantic HTML or accessible name query, then give your element a
`data-testid` and use `cy.findByTestId('my-element')` to find it in your test.
This should be a last resort, and will likely be most useful for scoping
selectors.

For further reading, check out
[Kent C. Dodd's article on making UI tests resilient to change](https://kentcdodds.com/blog/making-your-ui-tests-resilient-to-change).

## Common gotchas

We've noticed some common "gotchas" that can cause flakiness in our Cypress
tests.

### 1. Route changes should be followed by a unique selector

If the page changes, for example if your test steps click on a link to an
article, then it's important to make your next selector unique to the new page.
This makes sure that Cypress doesn't find a matching element on the page you
just left.

See the examples below of how to make these route changes more robust.

#### 🚫 Before: Route changes, but we find the `main` element on the previous page

```js
cy.findByRole('main').findByRole('link', { name: 'Test article' }).click();
// After clicking the link we can _sometimes_ accidentally get a reference to the 'main' element on the page we just left
cy.findByRole('main').findByRole('button', { name: 'Share post' });
// Cypress fails to find the 'Share post' button inside the previous page's `main` element, and the test fails
```

#### ✅ After: Route changes, and we find a unique element before proceeding

```js
cy.findByRole('main').findByRole('link', { name: 'Test article' }).click();
// The 'Share post' button doesn't exist on the page we just left, so Cypress will wait for it to be shown on the new page
cy.findByRole('button', { name: 'Share post' });
```

### 2. Interactive elements must be initialized before clicking

In a lot of places we present views in Rails-generated HTML and asynchronously
attach JavaScript event listeners after the page has loaded. This means that in
an automated test environment it is possible to click a button before its click
handler has been attached.

For this reason, it's important to double check how a feature's click handlers
are initialized and, if necessary, make sure Cypress waits for the button to be
ready to click.

See the examples below of how to make this kind of button interaction more
robust.

#### 🚫 Before: We click a button without waiting for initialization

```js
cy.findByRole('main').findByRole('link', { name: 'Test User Profile' }).click();
// We immediately try to click a button that's initialized asynchronously in JS. Sometimes the test will fail as the click handler is not yet attached.
cy.findByRole('button', { name: 'Follow' }).click();
```

#### ✅ After: We wait for a data attribute that indicates the initialization has completed

```js
cy.findByRole('main').findByRole('link', { name: 'Test User Profile' }).click();
// A data attribute is added to initialized follow buttons, and Cypress waits until this is present on the page
cy.get('[data-click-initialized]');
cy.findByRole('button', { name: 'Follow' }).click();
```

### 3. Lingering network requests interfere with test setup or new user login

Before each test we usually call `cy.testSetup()` to ensure cookies are cleared
and a user may be logged in fresh. However, if a previous test triggered
user-related network requests, and didn't wait until their completion, then
occasionally responses to these requests interfere with test setup and cause the
previous user to be persisted.

This is particularly prevalent in very short tests, but can also happen if you
try in the middle of a test to sign out as one user, and immediately log back in
as another.

This issue is best avoided by:

- Utilising custom Cypress commands (e.g. `cy.loginAndVisit(user, url)`,
  `cy.visitAndWaitForUserSideEffects(url)`, `cy.signOutUser()`) that help ensure
  side effects from network requests are accounted for
- Splitting tests into 'single user' tests (i.e. avoid logging in as multiple
  users in the same test)

#### 🚫 Before: Using the `cy.visit(url)` command directly without awaiting side effects

```js
beforeEach(() => {
  cy.testSetup();
  cy.fixture('users/articleEditorV2User.json').as('user');

  cy.get('@user').then(() => {
    cy.loginUser(user).then(() => {
      // The `visit` command does not take user-related network requests into account. If a test runs quickly, the responses may bleed into the next test setup
      cy.visit('/dashboard');
    });
  });
});
```

#### ✅ After: Using the custom `loginAndVisit` command

```js
beforeEach(() => {
  cy.testSetup();
  cy.fixture('users/articleEditorV2User.json').as('user');

  cy.get('@user').then(() => {
    // The custom command logs in the user and visits the page, ensuring that user-related network requests are awaited
    cy.loginAndVisit(user, '/dashboard');
  });
});
```

## Additional Resources

- [Cypress documentation](https://docs.cypress.io)
- [Making your UI tests resilient to change](https://kentcdodds.com/blog/making-your-ui-tests-resilient-to-change)
  by [Kent C. Dodds](https://twitter.com/kentcdodds)
- [Static vs Unit vs Integration vs E2E Testing for Frontend Apps](https://kentcdodds.com/blog/unit-vs-integration-vs-e2e-tests)
  by Kent C. Dodds
