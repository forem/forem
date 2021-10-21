# cypress-rails

This is a simple gem to make it easier to start writing browser tests with
[Cypress](http://cypress.io) for your [Rails](https://rubyonrails.org) apps,
regardless of whether your app is server-side rendered HTML, completely
client-side JavaScript, or something in-between.

## Installation

**tl;dr**:

1. Install the npm package `cypress`
2. Install this gem `cypress-rails`
3. Run `rake cypress:init`

### Installing Cypress itself

The first step is making sure Cypress is installed (that's up to you, this
library doesn't install Cypress, it just provides a little Rails-specific glue).

If you're on newer versions of Rails and using
[webpacker](https://www.github.com/rails/webpacker) for your front-end assets,
then you're likely already using yarn to manage your JavaScript dependencies. If
that's the case, you can add Cypress with:

```sh
$ yarn add --dev cypress
```

If you're not using yarn in conjunction with your Rails app, check out the
Cypress docs on getting it installed. At the end of the day, this gem just needs
the `cypress` binary to exist either in `./node_modules/.bin/cypress` or on your
`PATH`.

### Installing the cypress-rails gem

Now, to install the cypress-rails gem, you'll want to add it to your development
& test gem groups of your Gemfile, so that you have easy access to its rake
tasks:

```ruby
group :development, :test do
  gem "cypress-rails"
end
```

Once installed, you'll want to run:

```sh
$ rake cypress:init
```

This will override a few configurations in your `cypress.json` configuration
file.

## Usage

### Develop tests interactively with `cypress open`

When writing tests with Cypress, you'll find the most pleasant experience (by
way of a faster feedback loop and an interactive, easy-to-inspect test runner)
using the `cypress open` command.

When using Rails, however, you'll also want your Rails test server to be running
so that there's something for Cypress to interact with. `cypress-rails` provides
a wrapper for running `cypress open` with a dedicated Rails test server.

So, by running:

```sh
$ rake cypress:open
```

Any JavaScript files added to `cypress/integration` will be identified by
Cypress as tests. Simply click a test file in the Cypress application window to
launch the test in a browser. Each time you save the test file, it will re-run
itself.

### Run tests headlessly with `cypress run`

To run your tests headlessly (e.g. when you're in CI), you'll want the `run`
command:

```sh
$ rake cypress:run
```

## Managing your test data

The tricky thing about browser tests is that they usually depend on some test
data being available with which to exercise the app efficiently. Because cypress
is a JavaScript-based tool and can't easily manipulate your Rails app directly,
cypress-rails provides a number of hooks that you can use to manage your test
data.

Here's what a `config/initializers/cypress_rails.rb` initializer might look
like:

```ruby
return unless Rails.env.test?

CypressRails.hooks.before_server_start do
  # Called once, before either the transaction or the server is started
end

CypressRails.hooks.after_transaction_start do
  # Called after the transaction is started (at launch and after each reset)
end

CypressRails.hooks.after_state_reset do
  # Triggered after `/cypress_rails_reset_state` is called
end

CypressRails.hooks.before_server_stop do
  # Called once, at_exit
end
```

(You can find [an
example
initializer](/example/config/initializers/cypress_rails_initializer.rb)
in this repo.)

The gem also provides a special route on the test server:
`/cypress_rails_reset_state`. Each time it's called, cypress-rails will do
two things at the beginning of the next request received by the Rails app:

* If `CYPRESS_RAILS_TRANSACTIONAL_SERVER` is enabled, roll back the transaction,
effectively resetting the application state to whatever it was at the start of
the test run

* Trigger any `after_state_reset` hooks you've configured (regardless of the
  transactional server setting)

This way, you can easily instruct the server to reset its test state from your
Cypress tests like so:

```js
beforeEach(() => {
  cy.request('/cypress_rails_reset_state')
})
```

(Remember, in Cypress, `before` is a before-all hook and `beforeEach` is run
between each test case!)

## Configuration

### Environment variables

The cypress-rails gem is configured entirely via environment variables. If you
find yourself repeating a number of verbose environment variables as you run
your tests, consider invoking the gem from a custom script or setting your
preferred environment variables project-wide using a tool like
[dotenv](https://github.com/bkeepers/dotenv).


* **CYPRESS_RAILS_DIR** (default: `Dir.pwd`) the directory of your project
* **CYPRESS_RAILS_HOST** (default: `"127.0.0.1"`) the hostname to bind to
* **CYPRESS_RAILS_PORT** (default: _a random available port_) the port to run
  the Rails test server on
* **CYPRESS_RAILS_BASE_PATH** (default: `"/"`) the base path for all Cypress's
  requests to the app (e.g. via `cy.visit()`). If you've customized your
  `baseUrl` setting (e.g. in `cypress.json`), you'll need to duplicate it with
  this environment variable
* **CYPRESS_RAILS_TRANSACTIONAL_SERVER** (default: `true`) when true, will start
  a transaction on all database connections before launching the server. In
  general this means anything done during `cypress open` or `cypress run` will
  be rolled back on exit (similar to running a Rails System test)
* **CYPRESS_RAILS_CYPRESS_OPTS** (default: _none_) any options you want to
  forward to the Cypress CLI when running its `open` or `run` commands.

#### Example: Running a single spec from the command line

It's a little verbose, but an example of using the above options to run a single
Cypress test would look like this:

```
$ CYPRESS_RAILS_CYPRESS_OPTS="--spec cypress/integration/a_test.js" bin/rake cypress:run
```

#### Example: Running your tests in Chromium

By default, Cypress will run its tests in its packaged Electron app, unless you've configured it globally. To choose which browser it will run from the command line, try this:

```
$ CYPRESS_RAILS_CYPRESS_OPTS="--browser chromium" bin/rake cypress:run
```

### Initializer hooks

### before_server_start

Pass a block to `CypressRails.hooks.before_server_start` to register a hook that
will execute before the server or any transaction has been started. If you use
Rails fixtures, it may make sense to load them here, so they don't need to be
re-inserted for each request

### after_server_start

Pass a block to `CypressRails.hooks.after_server_start` to register a hook that
will execute after the server has booted.

### after_transaction_start

If there's any custom behavior or state management you want to do inside the
transaction (so that it's also rolled back each time a reset is triggered),
pass a block to `CypressRails.hooks.after_transaction_start`.

### after_state_reset

Every time the test server receives an HTTP request at
`/cypress_rails_reset_state`, the transaction will be rolled back (if
`CYPRESS_RAILS_TRANSACTIONAL_SERVER` is enabled) and the `after_state_reset`
hook will be triggered. To set up the hook, pass a block to
`CypressRails.hooks.after_state_reset`.

### before_server_stop

In case you've made any permanent changes to your test database that could
pollute other test suites or scripts, you can use the `before_server_stop` to
(assuming everything exits gracefully) clean things up and restore the state
of your test database. To set up the hook, pass a block to
`CypressRails.hooks.before_server_stop`.

## Configuring Rails

Beyond the configuration options above, you'll probably also want to disable caching
in your Rails app's [config/environments/test.rb](/example/config/environments/test.rb#L9)
file, so that changes to your Ruby code are reflected in your tests while you
work on them with `rake cypress:open`. (If either option is set to
`true`, any changes to your Ruby code will require a server restart to be reflected as you work
on your tests.)

To illustrate, here's what that might look like in `config/environments/test.rb`:

```ruby
config.cache_classes = false
config.action_view.cache_template_loading = false
```

## Setting up continuous integration

#### Circle CI

Nowadays, Cypress and Circle get along pretty well without much customization.
The only tricky bit is that Cypress will install its large-ish binary to
`~/.cache/Cypress`, so if you cache your dependencies, you'll want to include
that path:

```yml
version: 2
jobs:
  build:
    docker:
      - image: circleci/ruby:2.6-node-browsers
      - image: circleci/postgres:9.4.12-alpine
        environment:
          POSTGRES_USER: circleci
    steps:
      - checkout

      # Bundle install dependencies
      - type: cache-restore
        key: v1-gems-{{ checksum "Gemfile.lock" }}

      - run: bundle install --path vendor/bundle

      - type: cache-save
        key: v1-gems-{{ checksum "Gemfile.lock" }}
        paths:
          - vendor/bundle

      # Yarn dependencies
      - restore_cache:
          keys:
            - v1-yarn-{{ checksum "yarn.lock" }}
            # fallback to using the latest cache if no exact match is found
            - v1-yarn-

      - run: yarn install

      - save_cache:
          paths:
            - node_modules
            - ~/.cache
          key: v1-yarn-{{ checksum "yarn.lock" }}

      # Run your cypress tests
      - run: bin/rake cypress:run
```

## Why use this?

Rails ships with a perfectly competent browser-testing facility called [system
tests](https://guides.rubyonrails.org/testing.html#system-testing) which depend
on [capybara](https://github.com/teamcapybara/capybara) to drive your tests,
most often with [Selenium](https://www.seleniumhq.org). All of these tools work,
are used by lots of people, and are a perfectly reasonable choice when writing
full-stack tests of your Rails application.

So why would you go off the Rails to use Cypress and this gem, adding two
additional layers to the Jenga tower of testing facilities that Rails ships
with? Really, it comes down to the potential for an improved development
experience. In particular:

* Cypress's [IDE-like `open`
  command](https://docs.cypress.io/guides/getting-started/writing-your-first-test.html#Add-a-test-file)
  provides a highly visual, interactive, inspectable test runner. Not only can
  you watch each test run and read the commands as they're executed, Cypress
  takes a DOM snapshot before and after each command, which makes rewinding and
  inspecting the state of the DOM trivially easy, something that I regularly
  find myself losing 20 minutes attempting to do with Capybara
* `cypress open` enables an almost REPL-like feedback loop that is much faster
  and more information dense than using Capybara and Selenium. Rather than
  running a test from the command line, seeing it fail, then adding a debug
  breakpoint to a test to try to manipulate the browser or tweaking a call to a
  Capybara API method, failures tend to be rather obvious when using Cypress and
  fixing it is usually as easy as tweaking a command, hitting save, and watching
  it re-run
* With very few exceptions, a Cypress test that works in a browser window will
  also pass when run headlessly in CI
* Cypress selectors are [just jQuery
  selectors](https://api.jquery.com/category/selectors/), which makes them both
  more familiar and more powerful than the CSS and XPath selectors offered by
  Capybara. Additionally, Cypress makes it very easy to drop into a plain
  synchronous JavaScript function for [making more complex
  assertions](https://docs.cypress.io/guides/references/assertions.html#Should-callback)
  or composing repetitive tasks into [custom
  commands](https://docs.cypress.io/api/cypress-api/custom-commands.html#Syntax#article)
* Cypress commands are, generally, much faster than analogous tasks in Selenium.
  Where certain clicks and form inputs will hang for 300-500ms for seemingly no
  reason when running against Selenium WebDriver, Cypress commands tend to run
  as fast as jQuery can select and fill an element (which is, of course, pretty
  fast)
* By default, Cypress [takes a
  video](https://docs.cypress.io/guides/guides/screenshots-and-videos.html#Screenshots#article)
  of every headless test run, taking a lot of the mystery (and subsequent
  analysis & debugging) out of test failures in CI

Nevertheless, there are trade-offs to attempting this (most notably around
Cypress's [limited browser
support](https://docs.cypress.io/guides/guides/launching-browsers.html#Browsers)
and the complications to test data management), and I wouldn't recommend
adopting Cypress and writing a bunch of browser tests for every application.
But, if the above points sound like solutions to problems you experience, you
might consider trying it out.

## Code of Conduct

This project follows Test Double's [code of
conduct](https://testdouble.com/code-of-conduct) for all community interactions,
including (but not limited to) one-on-one communications, public posts/comments,
code reviews, pull requests, and GitHub issues. If violations occur, Test Double
will take any action they deem appropriate for the infraction, up to and
including blocking a user from the organization's repositories.

