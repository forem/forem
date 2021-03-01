<div align="center">
  <br>
  <h1>Forem 🌱</h1>
  <strong>For Empowering Community</strong>
</div>
<br>
<p align="center">
  <a href="https://www.ruby-lang.org/en/">
    <img src="https://img.shields.io/badge/Ruby-v2.7.2-green.svg" alt="ruby version">
  </a>
  <a href="http://rubyonrails.org/">
    <img src="https://img.shields.io/badge/Rails-v6.0.3-brightgreen.svg" alt="rails version">
  </a>
  <a href="https://travis-ci.com/forem/forem">
    <img src="https://travis-ci.com/forem/forem.svg?branch=master" alt="Travis Status for forem/forem">
  </a>
  <a href="https://codeclimate.com/github/forem/forem/maintainability">
    <img src="https://api.codeclimate.com/v1/badges/ce45bf63293073364bcb/maintainability" alt="Code Climate maintainability">
  </a>
  <a href="https://codeclimate.com/github/forem/forem/trends/technical_debt">
    <img src="https://img.shields.io/codeclimate/tech-debt/forem/forem" alt="Code Climate technical debt">
  </a>
  <a href="https://www.codetriage.com/forem/forem">
    <img src="https://www.codetriage.com/forem/forem/badges/users.svg" alt="CodeTriage badge">
  </a>
  <img src="https://badgen.net/dependabot/forem/forem?icon=dependabot" alt="Dependabot Badge">
  <a href="https://gitpod.io/from-referrer/">
    <img src="https://img.shields.io/badge/setup-automated-blue?logo=gitpod" alt="GitPod badge">
  </a>
  <a href="https://app.netlify.com/sites/docsdevto/deploys">
    <img src="https://api.netlify.com/api/v1/badges/e5dbe779-7bca-4390-80b9-6e678b4806a3/deploy-status" alt="Netlify badge">
  </a>
  <img src="https://img.shields.io/github/languages/code-size/forem/forem" alt="GitHub code size in bytes">
  <img src="https://img.shields.io/github/commit-activity/w/forem/forem" alt="GitHub commit activity">
  <a href="https://github.com/forem/forem/issues?q=is%3Aissue+is%3Aopen+label%3A%22ready+for+dev%22">
    <img src="https://img.shields.io/github/issues/forem/forem/ready for dev" alt="GitHub issues ready for dev">
  </a>
  <a href="https://app.honeybadger.io/project/Pl5JzZB5ax">
    <img src="https://img.shields.io/badge/honeybadger-active-informational" alt="Honeybadger badge">
  </a>
  <a href="https://knapsackpro.com/dashboard/organizations/1142/projects/1022/test_suites/1434/builds">
    <img src="https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20dev.to-%230074ff" alt="Knapsack Pro Parallel CI builds for dev.to" style="max-width:100%;">
  </a>
</p>

Welcome to the [Forem](https://forem.com) codebase, the platform that powers
[dev.to](https://dev.to). We are so excited to have you. With your help, we can
build out Forem’s usability, scalability, and stability to better serve our
communities.

## What is Forem?

Forem is open source software for building communities. Communities for your
peers, customers, fanbases, families, friends, and any other time and space
where people need to come together to be part of a collective.
[See our announcement post](https://dev.to/devteam/for-empowering-community-2k6h)
for a high-level overview of what Forem is.

[dev.to](https://dev.to) (or just DEV) is hosted by Forem. It is a community of
software developers who write articles, take part in discussions, and build
their professional profiles. We value supportive and constructive dialogue in
the pursuit of great code and career growth for all members. The ecosystem spans
from beginner to advanced developers, and all are welcome to find their place
within our community. ❤️

## Table of Contents

- [What is Forem?](#what-is-forem)
- [Table of Contents](#table-of-contents)
- [Community](#community)
- [Contributing](#contributing)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
    - [Local](#local)
    - [Containers](#containers)
  - [Installation Documentation](#installation-documentation)
- [Developer Documentation](#developer-documentation)
- [Core team](#core-team)
- [Vulnerability disclosure](#vulnerability-disclosure)
- [License](#license)

## Community

For a place to have open discussions on features, voice your ideas, or get help
with general questions please visit our community at
[forem.dev](https://forem.dev/).

## Contributing

We encourage you to contribute to Forem! Please check out the
[Contributing to Forem guide](CONTRIBUTING.md) for guidelines about how to
proceed.

## Getting Started

This section provides a high-level quick start guide. If you're looking for the
[installation guide](https://docs.forem.com/installation/), you'll want to refer
to our complete [Developer Documentation](https://docs.forem.com/).

We run on a [Rails](https://rubyonrails.org/) backend, and we are currently
transitioning to a [Preact](https://preactjs.com/)-first frontend.

A more complete overview of our stack is available in
[our docs](https://docs.forem.com/technical-overview/).

### Prerequisites

#### Local

- [Ruby](https://www.ruby-lang.org/en/): we recommend using
  [rbenv](https://github.com/rbenv/rbenv) to install the Ruby version listed on
  the badge.
- [Yarn](https://yarnpkg.com/) 1.x: please refer to their
  [installation guide](https://classic.yarnpkg.com/en/docs/install).
- [PostgreSQL](https://www.postgresql.org/) 11 or higher.
- [ImageMagick](https://imagemagick.org/): please refer to ImageMagick's
  [installation instructions](https://imagemagick.org/script/download.php).
- [Redis](https://redis.io/) 4 or higher.
- [Elasticsearch](https://www.elastic.co) 7 or higher.

#### Containers

**Linux**

- [Podman](https://github.com/containers/libpod) 1.9.2 or higher
- [Podman Compose](https://github.com/containers/podman-compose) 0.1.5 or higher

**OS X**

- [Docker Desktop for Mac](https://docs.docker.com/docker-for-mac/install/)

### Installation Documentation

[View Full Installation Documentation](https://docs.forem.com/installation/).

## Developer Documentation

[Check out our dedicated docs page for more technical documentation](https://docs.forem.com).

## Core team

- [@benhalpern](https://dev.to/ben)
- [@jessleenyc](https://dev.to/jess)
- [@peterkimfrank](https://dev.to/peter)
- [@maestromac](https://dev.to/maestromac)
- [@zhao-andy](https://dev.to/andy)
- [@lightalloy](https://dev.to/lightalloy)
- [@rhymes](https://dev.to/rhymes)
- [@jacobherrington](https://dev.to/jacobherrington)
- [@mstruve](https://dev.to/molly_struve)
- [@atsmith813](https://dev.to/atsmith813)
- [@citizen428](https://dev.to/citizen428)
- [@nickytonline](https://dev.to/nickytonline)
- [@joshpuetz](http://dev.to/joshpuetz)
- [@vaidehijoshi](https://dev.to/vaidehijoshi)
- [@juliannatetreault](https://dev.to/juliannatetreault)
- [@ridhwana](https://dev.to/ridhwana)
- [@fdoxyz](https://dev.to/fdoxyz)
- [@msarit](https://dev.to/msarit)
- [@jdoss](https://dev.to/jdoss)
- [@cmgorton](https://dev.to/coffeecraftcode)
- [@andygeorge](https://dev.to/andygeorge)
- [@phannon716](https://dev.to/phannon716)
- [@katiedavis](https://dev.to/katiedavis)
- [@s_aitchison](https://dev.to/s_aitchison)

## Vulnerability disclosure

Forem is the open source software which powers [DEV](https://dev.to).

We welcome security research on DEV under the terms of our
[vulnerability disclosure policy](https://dev.to/security).

## Acknowledgments

Thank you to the [Twemoji project](https://github.com/twitter/twemoji) for the
usage of their emojis.

## License

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version. Please see the [LICENSE](./LICENSE.md) file in our repository for
the full text.

Like many open source projects, we require that contributors provide us with a
Contributor License Agreement (CLA). By submitting code to the Forem project,
you are granting us a right to use that code under the terms of the CLA.

Our version of the CLA was adapted from the Microsoft Contributor License
Agreement, which they generously made available to the public domain under
Creative Commons CC0 1.0 Universal.

Any questions, please refer to our
[license FAQ](https://docs.forem.com/licensing/) doc or email yo@dev.to.

<br>

<p align="center">
  <img alt="Sloan, the sloth mascot" width="250px" src="https://thepracticaldev.s3.amazonaws.com/uploads/user/profile_image/31047/af153cd6-9994-4a68-83f4-8ddf3e13f0bf.jpg">
  <br>
  <strong>Happy Coding</strong> ❤️
</p>

[⬆ Back to Top](#Table-of-contents)
