# Honeycomb Beeline for Ruby

[![OSS Lifecycle](https://img.shields.io/osslifecycle/honeycombio/beeline-ruby?color=success)](https://github.com/honeycombio/home/blob/main/honeycomb-oss-lifecycle-and-practices.md)
[![Build Status](https://circleci.com/gh/honeycombio/beeline-ruby.svg?style=svg)](https://circleci.com/gh/honeycombio/beeline-ruby)
[![Gem Version](https://badge.fury.io/rb/honeycomb-beeline.svg)](https://badge.fury.io/rb/honeycomb-beeline)

This package makes it easy to instrument your Ruby web app to send useful events to [Honeycomb](https://www.honeycomb.io), a service for debugging your software in production.
- [Usage and Examples](https://docs.honeycomb.io/getting-data-in/beelines/ruby-beeline/)

Sign up for a [Honeycomb
trial](https://ui.honeycomb.io/signup) to obtain an API key before starting.

## Compatible with

Requires Ruby version 2.3 or later

Built in instrumentation for:

- Active Support
- AWS (v2 and v3)
- Faraday
- Rack
- Rails (tested on versions 4.1 and up)
- Redis (tested on versions 3.x and 4.x)
- Sequel
- Sinatra

## Testing
Find `rspec` test files in the `spec` directory.

To run tests on gem-specific instrumentations or across various dependency versions, use [appraisal](https://github.com/thoughtbot/appraisal) (further instructions in the readme for that gem). Find gem sets in the `Appraisals` config.

To run a specific file: `bundle exec appraisal <gem set> rspec <path/to/file>`

## Get in touch

Please reach out to [support@honeycomb.io](mailto:support@honeycomb.io) or ping
us with the chat bubble on [our website](https://www.honeycomb.io) for any
assistance. We also welcome [bug reports](https://github.com/honeycombio/beeline-ruby/issues).

## Contributions

Features, bug fixes and other changes to `beeline-ruby` are gladly accepted. Please
open issues or a pull request with your change. Remember to add your name to the
CONTRIBUTORS file!

All contributions will be released under the Apache License 2.0.
