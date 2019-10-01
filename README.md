<div align="center">
  <br>
  <img alt="DEV" src="https://thepracticaldev.s3.amazonaws.com/i/ro3538by3b2fupbs63sr.png" width="500px">
  <h1>DEV Community 👩‍💻👨‍💻</h1>
  <strong>The Human Layer of the Stack</strong>
</div>
<br>
<p align="center">
  <a href="https://www.ruby-lang.org/en/">
    <img src="https://img.shields.io/badge/Ruby-v2.6.3-green.svg" alt="ruby version">
  </a>
  <a href="http://rubyonrails.org/">
    <img src="https://img.shields.io/badge/Rails-v5.2.3-brightgreen.svg" alt="rails version">
  </a>
  <a href="https://travis-ci.com/thepracticaldev/dev.to">
    <img src="https://travis-ci.com/thepracticaldev/dev.to.svg?branch=master" alt="Travis Status for thepracticaldev/dev.to">
  </a>
  <a href="https://codeclimate.com/github/thepracticaldev/dev.to/maintainability">
    <img src="https://api.codeclimate.com/v1/badges/ce45bf63293073364bcb/maintainability" alt="Code Climate maintainability">
  </a>
  <a href="https://codeclimate.com/github/thepracticaldev/dev.to/test_coverage">
    <img src="https://api.codeclimate.com/v1/badges/ce45bf63293073364bcb/test_coverage" alt="Code Climate test coverage">
  </a>
  <a href="https://oss.skylight.io/app/applications/K9H5IV3RqKGu">
    <img src="https://badges.skylight.io/status/K9H5IV3RqKGu.svg?token=Ofd-9PTSyus3BqEZZZbM1cWKJ94nHWaPiTphGsWJMAY" alt="Skylight badge">
  </a>
  <a href="https://www.codetriage.com/thepracticaldev/dev.to">
    <img src="https://www.codetriage.com/thepracticaldev/dev.to/badges/users.svg" alt="CodeTriage badge">
  </a>
  <img src="https://flat.badgen.net/dependabot/thepracticaldev/dev.to?icon=dependabot" alt="Dependabot Badge" />
</p>

Welcome to the [dev.to](https://dev.to) codebase. We are so excited to have you. With your help, we can build out DEV to be more stable and better serve our community.

## What is dev.to?

[dev.to](https://dev.to) (or just DEV) is a platform where software developers write articles, take part in discussions, and build their professional profiles. We value supportive and constructive dialogue in the pursuit of great code and career growth for all members. The ecosystem spans from beginner to advanced developers, and all are welcome to find their place within our community. ❤️

## Table of Contents

- [Contributing](#contributing)
- [Codebase](#codebase)
  - [The stack](#the-stack)
  - [Engineering standards](#engineering-standards)
    - [Style guide](#style-guide)
    - [Husky hooks](#husky-hooks)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Standard Installation](#standard-installation)
  - [Docker Installation (BETA)](#docker-installation-beta)
  - [Starting the application](#starting-the-application)
  - [Suggested Workflow](#suggested-workflow)
- [Additional docs](#additional-docs)
- [Core Team Members](#core-team)
- [License](#license)

## Contributing

We encourage you to contribute to dev.to! Please check out the [Contributing to dev.to guide](CONTRIBUTING.md) for guidelines about how to proceed.

## Codebase

### The stack

We run on a Rails backend with mostly vanilla JavaScript on the front end, and some Preact sprinkled in. One of our goals is to move to mostly Preact for our front end.

Additional technologies and services are listed on [our docs](https://docs.dev.to/technical-overview/).

## Getting Started

This section provides a high-level requirement & quick start guide. **For detailed installations, such as getting started with GitPod, Docker, or specific operating systems, please check out our [docs](http://docs.dev.to).**

### Prerequisites

- [Ruby](https://www.ruby-lang.org/en/): we recommend using [rbenv](https://github.com/rbenv/rbenv) to install the Ruby version listed on the badge.
- [Yarn](https://yarnpkg.com/): please refer to their [installation guide](https://yarnpkg.com/en/docs/install).
- [PostgreSQL](https://www.postgresql.org/) 9.4 or higher.

### Standard Installation

1. Make sure all the prerequisites are installed.
1. Fork dev.to repository, ie. https://github.com/thepracticaldev/dev.to/fork
1. Clone your forked repository, ie. `git clone https://github.com/<your-username>/dev.to.git`
1. Set up your environment variables/secrets

   - Take a look at `Envfile`. This file lists all the `ENV` variables we use and provides a fake default for any missing keys. You'll need to get your own free [Algolia credentials](https://docs.dev.to/backend/algolia/) to get your development environment running.
   - This [guide](https://docs.dev.to/backend/) will show you how to get free API keys for additional services that may be required to run certain parts of the app.
   - For any key that you wish to enter/replace:
     1. Create `config/application.yml` by copying from the provided template (ie. with bash: `cp config/sample_application.yml config/application.yml`). This is a personal file that is ignored in git.
     2. Obtain the development variable and apply the key you wish to enter/replace. ie:
     ```
     GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
     GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
     ```
   - If you are missing `ENV` variables on bootup, `envied` gem will alert you with messages similar to `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
   - You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.

1. Run `bin/setup`
1. That's it! Run `bin/startup` to start the application and head to `http://localhost:3000/`

[View Full Installation Documentation](https://docs.dev.to/installation/)

#### Starting the application

We're mostly a Rails app, with a bit of Webpack sprinkled in. **For most cases, simply running `bin/rails server` will do.** If you're working with Webpack though, you'll need to run the following:

- Run **`bin/startup`** to start the server, Webpack, and our job runner `delayed_job`. `bin/startup` runs `foreman start -f Procfile.dev` under the hood.
- `alias start="bin/startup"` makes this even faster. 😊
- If you're using **`pry`** for debugging in Rails, note that using `foreman` and `pry` together works, but it's not as clean as `bin/rails server`.

Here are some singleton commands you may need, usually in a separate instance/tab of your shell.

- Running the job server (if using `bin/rails server`) -- this is mostly for notifications and emails: **`bin/rails jobs:work`**
- Clearing jobs (in case you don't want to wait for the backlog of jobs): **`bin/rails jobs:clear`**

Current gotchas: potential environment issues with external services need to be worked out.

#### Suggested Workflow

We use [Spring](https://github.com/rails/spring), and it is already included in the project.

1.  Use the provided bin stubs to start Spring automatically, i.e. `bin/rails server`, `bin/rspec spec/models/`, `bin/rails db:migrate`.
1.  If Spring isn't picking up on new changes, use `spring stop`. For example, Spring should always be restarted if there's a change in environment key.
1.  Check Spring's status whenever with `spring status`.

Caveat: `bin/rspec` is not equipped with Spring because it affects Simplecov's result. Instead, use `bin/spring rspec`.

## Additional docs

[Check out our dedicated docs page for more technical documentation.](https://docs.dev.to)

## Core team

- [@benhalpern](https://dev.to/ben)
- [@jessleenyc](https://dev.to/jess)
- [@peterkimfrank](https://dev.to/peter)
- [@maestromac](https://dev.to/maestromac)
- [@zhao-andy](https://dev.to/andy)
- [@lightalloy](https://dev.to/lightalloy)
- [@rhymes](https://dev.to/rhymes)
- [@jacobherrington](https://dev.to/jacobherrington)

## Vulnerability disclosure

We welcome security research on DEV under the terms of our [vulnerability disclosure policy](https://dev.to/security).

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. Please see the [LICENSE](./LICENSE.md) file in our repository for the full text.

Like many open source projects, we require that contributors provide us with a Contributor License Agreement (CLA). By submitting code to the DEV project, you are granting us a right to use that code under the terms of the CLA.

Our version of the CLA was adapted from the Microsoft Contributor License Agreement, which they generously made available to the public domain under Creative Commons CC0 1.0 Universal.

Any questions, please refer to our [license FAQ](https://docs.dev.to/licensing/) doc or email yo@dev.to

<br>

<p align="center">
  <img alt="Sloan, the sloth mascot" width="250px" src="https://thepracticaldev.s3.amazonaws.com/uploads/user/profile_image/31047/af153cd6-9994-4a68-83f4-8ddf3e13f0bf.jpg">
  <br>
  <strong>Happy Coding</strong> ❤️
</p>
