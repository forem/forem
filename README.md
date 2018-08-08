<div align="center">
  <br>
  <img
    alt="DEV"
    src="https://thepracticaldev.s3.amazonaws.com/i/d3o5l9yiqfv1z24cn1yp.png"
    width=500px
  />
  <br/>
  <h1>DEV Community 👩‍💻👨‍💻</h1>
  <strong>The Human Layer of the Stack</strong>
</div>
<br/>
<p align="center">
  <a href="https://www.ruby-lang.org/en/">
    <img src="https://img.shields.io/badge/Ruby-v2.5.1-green.svg" alt="ruby version"/>
  </a>
  <a href="http://rubyonrails.org/">
    <img src="https://img.shields.io/badge/Rails-v5.1.6-brightgreen.svg" alt="rails version"/>
  </a>
  <a href="https://travis-ci.com/thepracticaldev/dev.to">
    <img src="https://travis-ci.com/thepracticaldev/dev.to.svg?branch=master" alt="Travis Status for thepracticaldev/dev.to"/>
  </a>
  <a href="https://codeclimate.com/github/thepracticaldev/dev.to/maintainability">
    <img src="https://api.codeclimate.com/v1/badges/ce45bf63293073364bcb/maintainability" />
  </a>
  <a href="https://codeclimate.com/github/thepracticaldev/dev.to/test_coverage">
    <img src="https://api.codeclimate.com/v1/badges/ce45bf63293073364bcb/test_coverage" />
  </a>
  <a href="https://www.skylight.io/app/applications/K9H5IV3RqKGu">
    <img src="https://badges.skylight.io/status/K9H5IV3RqKGu.svg?token=Ofd-9PTSyus3BqEZZZbM1cWKJ94nHWaPiTphGsWJMAY" />
  </a>
</p>

Welcome to the [dev.to](https://dev.to) codebase. We are so excited to have you. With your help, we can build out DEV to be more stable and better serve our community.

## Table of Contents

- [Contributing](#contributing)
  - [Where to contribute](#where-to-contribute)
  - [How to contribute](#how-to-contribute)
  - [Contribution guideline](#contribution-guideline)
    - [Clean code with tests](#clean-code-with-tests)
    - [Create a pull request](#create-a-pull-request)
    - [Creating an issue](#creating-an-issue)
  - [How to get help](#how-to-get-help)
  - [The bottom line](#the-bottom-line)
- [Codebase](#codebase)
  - [The stack](#the-stack)
  - [Engineering standards](#engineering-standards)
    - [Style guide](#style-guide)
    - [Husky hooks](#husky-hooks)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Starting the application](#starting-the-application)
  - [Suggested Workflow](#suggested-workflow)
- [Additional docs](#additional-docs)
- [Product Roadmap](#product-roadmap)
- [Core Team Members](#core-team)
- [License](#license)

## Contributing
We expect contributors to abide by our underlying [code of conduct](https://dev.to/code-of-conduct). All conversations and discussions on GitHub (issues, pull requests) and across dev.to must be respectful and harrassment-free.

### Where to contribute
When in doubt, ask a [core team member](#core-team)! You can mention us in any issues or ask on the [DEV Contributor thread](https://dev.to/devteam/devto-open-source-helpdiscussion-thread-v0-1l45). Any issue with `good first issue` tag is typically a good place to start.

**Refactoring** code, e.g. improving the code without modifying the behavior is an area that can probably be done based on intuition and may not require much communication to be merged.

**Fixing bugs** may also not require a lot of communication, but the more the better. Please surround bug fixes with ample tests. Bugs are magnets for other bugs. Write tests near bugs!

**Building features** is the area which will require the most communication and/or negotiation. Every feature is subjective and open for debate. The [product roadmap](https://github.com/thepracticaldev/dev.to/projects) should be a good guide to follow. As always, when in doubt, ask!

### How to contribute
1. Fork the project & clone locally. Follow the initial setup [here](#getting-started).
2. Create a branch, naming it either a feature or bug: `git checkout -b feature/that-new-feature` or `bug/fixing-that-bug`
3. Code and commit your changes. Bonus points if you write a [good commit message](https://chris.beams.io/posts/git-commit/): `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/that-new-feature`
5. [Create a pull request](#create-a-pull-request) for your branch 🎉

### Contribution guideline

### Create an issue
Nobody's perfect. Something doesn't work? or could be done better? Let us know by creating an issue.

PS: a clear and detailed issue gets lots of love, all you have to do is follow the issue template!

#### Clean code with tests
Some existing code may be poorly written or untested, so we must have more scrutiny going forward. We test with [rspec](http://rspec.info/), let us know if you have any questions about this!

#### Create a pull request
* Try to keep the pull requests small; a pull request should try its very best to address only a single concern.
* Make sure all tests pass and add additional tests for the code you submit.
* Document your reasoning behind the changes. Explain why you wrote the code in the way you did; the code should explain what it does.
* If there's an existing issue related to the pull request, reference to it by adding something like `References/Closes/Fixes/Resolves #305`, where 305 is the issue number. [More info here](https://github.com/blog/1506-closing-issues-via-pull-requests)
* If you follow the pull request template, you can't go wrong.

_Please note: all commits in a pull request will be squashed when merged, but when your PR is approved and passes our CI, it will be live on production!_

### How to get help
Whether you are stuck with feature implementation, first-time setup, or you just want to tell us something could be done better, check out our [OSS thread](https://dev.to/devteam/devto-open-source-helpdiscussion-thread-v0-1l45) or create an issue. You can also mention any [core team member](#core-team) in an issue and we'll respond as soon as possible.

### 👉 [OSS Help/Discussion Thread](https://dev.to/devteam/devto-open-source-helpdiscussion-thread-v0-1l45) 👈

### The bottom line
We are all humans trying to work together to improve the community. Always be kind and appreciate the need for tradeoffs. ❤️

## Codebase

### The stack
We run on a Rails backend with mostly vanilla JavaScript on the front end, and some Preact sprinkled in. One of our goals is to move to mostly Preact for our front end.

Additional technologies and services are listed on [our docs](https://docs.dev.to).

### Engineering standards
#### Style Guide
This project follows [Thoughtbot's Ruby Style Guide](https://github.com/thoughtbot/guides/blob/master/style/ruby/.rubocop.yml), using [Rubocop](https://github.com/bbatsov/rubocop) along with [Rubocop-Rspec](https://github.com/backus/rubocop-rspec) as the code analyzer. If you have Rubocop installed with your text editor of choice, you should be up and running.

For Javascript, we follow [Airbnb's JS Style Guide](https://github.com/airbnb/javascript), using [ESLint](https://eslint.org) and [prettier](https://github.com/prettier/prettier). If you have ESLint installed with your text editor of choice, you should be up and running.

#### Husky hooks
When commits are made, a git precommit hook runs via [husky](https://github.com/typicode/husky) and [lint-staged](https://github.com/okonet/lint-staged). ESLint, prettier, and Rubocop will run on your code before it's committed. If there are linting errors that can't be automatically fixed, the commit will not happen. You will need to fix the issue manually then attempt to commit again.

Note: if you've already installed the [husky](https://github.com/typicode/husky) package at least once (used for precommit npm script), you will need to run `yarn --force` or `npm install --no-cache`. For some reason, the post-install script of husky does not run when the package is pulled from yarn or npm's cache. This is not husky specific, but rather a cached package issue.

## Getting Started

### prerequisites
These prerequisites assume you are running macOS. If you are running a different OS, you should install these prerequisites specific to your OS.

* Ruby: we recommend using [rbenv](https://github.com/rbenv/rbenv) to install the Ruby version listed on the badge.
* Bundler: `gem install bundler`
* Foreman: `gem install foreman`
* Yarn: use `brew install yarn` to install yarn. It will also install node if you don't already have it.
* PostgreSQL: the easiest way to get started with this is to use [Postgres.app](https://postgresapp.com/).

### Installation
1.  `git clone git@github.com:thepracticaldev/dev.to.git`
2.  `bundle install`
3.  `bin/yarn`
4.  Set up your environment variables/secrets
    * Take a look at `Envfile`. This file lists all the `ENV` variables we use and provides a fake default for any missing keys. You'll need to get your own free [Algolia credentials](http://docs.dev.to/get-api-keys-dev-env/#algolia-(choose-oauth-or-email-sign-up)) to get your development environment running.
    * This [guide](http://docs.dev.to/get-api-keys-dev-env/) will show you how to get free API keys for additional servies that may be required to run certain parts of the app.
    * For any key that you wish to enter/replace:
      1. Create `config/application.yml` by copying from the provided template (`cp config/sample_application.yml config/application.yml`). This is a personal file that is ignored in git.
      2. Obtain the development variable and apply the key you wish to enter/replace. ie:
      ```
      GITHUB_KEY: "afaslkjdflkj2398jflskdjfljk"
      GITHUB_SECRET: "23r8dcvlk23jekljfslkdfjlks"
      ```
    * If you are missing `ENV` variables on bootup, `envied` gem will alert you with messages similar to `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
    * You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.
5.  Run `bin/setup`

#### Starting the application
We're mostly a Rails app, with a bit of Webpack sprinkled in. **For most cases, simply running `bin/rails server` will do.** If you're working with Webpack though, you'll need to run the following:

* Run **`bin/startup`** to start the server, Webpack, and our job runner `delayed_job`. `bin/startup` runs `foreman start -f Procfile.dev` under the hood.
* `alias start="bin/startup"` makes this even faster. 😊
* If you're using **`pry`** for debugging in Rails, note that using `foreman` and `pry` together works, but it's not as clean as `bin/rails server`.

Here are some singleton commands you may need, usually in a separate instance/tab of your shell.

* Running the job server (if using `bin/rails server`) -- this is mostly for notifications and emails: **`bin/rails jobs:work`**
* Clearing jobs (in case you don't want to wait for the backlog of jobs): **`bin/rails jobs:clear`**

Current gotchas: potential environment issues with external services need to be worked out.

#### Suggested Workflow
We use [Spring](https://github.com/rails/spring) and it is already included in the project.

1.  Use the provided bin stubs to automatically start Spring, i.e. `bin/rails server`, `bin/rspec spec/models/`, `bin/rake db:migrate`.
2.  If Spring isn't picking up on new changes, use `spring stop`. For example, Spring should always be restarted if there's a change in environment key.
3.  Check Spring's status whenever with `spring status`.

Caveat: `bin/rspec` is not equipped with Spring because it affects Simplecov's result. Instead use `bin/spring rspec`.

## Additional docs
[Check out our dedicated docs page for more technical documentation.](https://docs.dev.to)

## Product Roadmap

Our new product roadmap can be found [here](https://github.com/thepracticaldev/dev.to/projects/1). Many notes need to be converted to issues but this should provide an overview of features we plan to work on, as well as features we are considering.

Core team members will move issues along the project board as they progress.

- Ideas & Requests: features up for discussion.
- Needs Owners: features in need of an owner.
- Committed: features we're committed to building -- free for contributors to work on, but please communicate with the owner beforehand.
- In Progress (early stage): work has begun on feature.
- In Progress (late stage): feature is near completion.

## Core team

- [@benhalpern](https://dev.to/ben)
- [@jessleenyc](https://dev.to/jess)
- [@peterkimfrank](https://dev.to/peter)
- [@maestromac](https://dev.to/maestromac)
- [@zhao-andy](https://dev.to/andy)

## License
DEV is licensed under the GNU Affero General Public License 3 (AGPL-3).  Please see the [LICENSE](./LICENSE.md) file in our repository for the full text.

Like many open source projects, we require that contributors provide us with a Contributor License Agreement (CLA).  By submitting code to the DEV project, you are granting us a right to use that code under the terms of the CLA.

Our version of the CLA was adapted from the Microsoft Contributor License Agreement, which they generously made available to the public domain under Creative Commons CC0 1.0 Universal.

Any questions, please refer to our [license FAQ](http://docs.dev.to/license-faq/) doc or email yo@dev.to

<br/>

<p align="center">
  <img
    alt="sloan"
    width=250px
    src="https://thepracticaldev.s3.amazonaws.com/uploads/user/profile_image/31047/af153cd6-9994-4a68-83f4-8ddf3e13f0bf.jpg"
  />
  <br/>
  <strong>Happy Coding</strong> ❤️
</p>
