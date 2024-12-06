# Guard

**IMPORTANT: Please upgrade to Ruby >= 2.4 before installing Guard! To install for older versions, update Bundler at least 1.12: `gem update bundler` and Bundler should correctly resolve to earlier gems for your given Ruby version.**

- [Ruby 2.1 is officially outdated and unsupported!](https://www.ruby-lang.org/en/news/2016/03/30/ruby-2-1-9-released/)
- [Ruby 2.2 is officially outdated and unsupported!](https://www.ruby-lang.org/en/news/2018/06/20/support-of-ruby-2-2-has-ended/)
- [Ruby 2.3 is officially outdated and unsupported!](https://www.ruby-lang.org/en/news/2019/03/31/support-of-ruby-2-3-has-ended/)

:exclamation: Guard is currently accepting more maintainers. Please [read this](https://github.com/guard/guard/wiki/Maintainers) if you're interested in joining the team.

[![Gem Version](https://img.shields.io/gem/v/guard.svg?style=flat)](https://rubygems.org/gems/guard) [![Build Status](https://travis-ci.org/guard/guard.svg?branch=master)](https://travis-ci.org/guard/guard) [![Code Climate](https://codeclimate.com/github/guard/guard/badges/gpa.svg)](https://codeclimate.com/github/guard/guard) [![Test Coverage](https://codeclimate.com/github/guard/guard/badges/coverage.svg)](https://codeclimate.com/github/guard/guard) [![Inline docs](http://inch-ci.org/github/guard/guard.svg)](http://inch-ci.org/github/guard/guard) [![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

<img src="http://f.cl.ly/items/0A0M3W2x3I1P450z341U/guard-Icon.png" alt="Guard Icon" align="right" />
Guard automates various tasks by running custom rules whenever file or directories are modified.

It's frequently used by software developers, web designers, writers and other specialists to avoid mundane, repetitive actions and commands such as "relaunching" tools after changing source files or configurations.

Common use cases include: an IDE replacement, web development tools, designing "smart" and "responsive" build systems/workflows, automating various project tasks and installing/monitoring various system services.

For a full categorized list of known Guard plugins, look here: https://github.com/guard/guard/wiki/Guard-Plugins

If you have
any questions about Guard or want to share some information with the Guard community, please go to one of
the following places:

* [Guard Wiki](https://github.com/guard/guard/wiki)
* [Google+ community](https://plus.google.com/communities/110022199336250745477).
* [Google group](http://groups.google.com/group/guard-dev).
* [StackOverflow](http://stackoverflow.com/questions/tagged/guard).
* IRC channel `#guard` (irc.freenode.net) for chatting.

Before you file an issue, make sure you have read the _[known issues](#issues)_ and _[file an issue](#file-an-issue)_ sections that contains some important information.

## Features

* File system changes handled by our awesome [Listen](https://github.com/guard/listen) gem.
* Support for visual system notifications.
* Huge eco-system with [more than 300](https://rubygems.org/search?query=guard-) Guard plugins.
* Tested against the latest Ruby 2.4.x, 2.5.x, 2.6.x, JRuby & Rubinius. See [`.travis-ci.yml`](https://github.com/guard/guard/blob/master/.travis.yml) for the exact versions.

## Screencast

Two nice screencasts are available to help you get started:

* [Guard](http://railscasts.com/episodes/264-guard) on RailsCast.
* [Guard is Your Best Friend](http://net.tutsplus.com/tutorials/tools-and-tips/guard-is-your-best-friend) on Net Tuts+.

## Installation

The simplest way to install Guard is to use [Bundler](http://bundler.io).

Add Guard (and any other dependencies) to a `Gemfile` in your project’s root:

```ruby
group :development do
  gem 'guard'
end
```

then install it by running Bundler:

```bash
$ bundle
```

Generate an empty `Guardfile` with:

```bash
$ bundle exec guard init
```

Run Guard through Bundler with:

```bash
$ bundle exec guard
```

If you are on Mac OS X and have problems with either Guard not reacting to file
changes or Pry behaving strange, then you should [add proper Readline support
to Ruby on macOS](https://github.com/guard/guard/wiki/Add-Readline-support-to-Ruby-on-Mac-OS-X).

## Avoiding gem/dependency problems

**It's important that you always run Guard through Bundler to avoid errors.**

If you're getting sick of typing `bundle exec` all the time, try one of the following:

* (Recommended) Running `bundle binstub guard` will create `bin/guard` in your
  project, which means running `bin/guard` (tab completion will save you a key
  stroke or two) will have the exact same result as `bundle exec guard`.

* Or, you can `alias be="bundle exec"` in your `.bashrc` or similar and the execute only `be guard`.
  **Protip**: It will work for all comands executed in `bundle exec` context!


* Or, for RubyGems >= 2.2.0 (at least, though the more recent the better),
  simply set the `RUBYGEMS_GEMDEPS` environment variable to `-` (for autodetecting
  the Gemfile in the current or parent directories) or set it to the path of your Gemfile.

(To upgrade RubyGems from RVM, use the `rvm rubygems` command).

*NOTE: this Rubygems feature is still under development still lacks many features of bundler*

* Or, for RubyGems < 2.2.0 check out the [Rubygems Bundler](https://github.com/rvm/rubygems-bundler).

## Add Guard plugins

Guard is now ready to use and you should add some Guard plugins for your specific use. Start exploring the many Guard
plugins available by browsing the [Guard organization](https://github.com/guard) on GitHub or by searching for `guard-`
on [RubyGems](https://rubygems.org/search?utf8=%E2%9C%93&query=guard-).

When you have found a Guard plugin of your interest, add it to your `Gemfile`:

```ruby
group :development do
  gem '<guard-plugin-name>'
end
```

See the init section of the Guard usage below to see how to install the supplied plugin template that you can install and
to suit your needs.

## Usage

Guard is run from the command line. Please open your terminal and go to your project work directory.

Look here for a full [list of Guard commands](https://github.com/guard/guard/wiki/List-of-Guard-Commands)

### Start

Just launch Guard inside your Ruby or Rails project with:

```bash
$ bundle exec guard
```

Guard will look for a `Guardfile` or `guardfile.rb` in your current directory. If it does not find one, it will look
in your `$HOME` directory for a `.Guardfile`.

Please look here to see all the [command line options for Guard](https://github.com/guard/guard/wiki/Command-line-options-for-Guard)

## Interactions

Please read how to [interact with Guard](https://github.com/guard/guard/wiki/Interacting-with-Guard) on the console and which [signals](https://github.com/guard/guard/wiki/Interacting-with-Guard#guard-signals) Guard accepts


## Guardfile DSL

For details on extending your `Guardfile` look at [Guardfile examples](https://github.com/guard/guard/wiki/Guardfile-examples) or look at a list of commands [Guardfile-DSL / Configuring-Guard](https://github.com/guard/guard/wiki/Guardfile-DSL---Configuring-Guard)

## Issues

Before reporting a problem, please read how to [File an issue](https://github.com/guard/guard/blob/master/CONTRIBUTING.md#file-an-issue).

## Development / Contributing

See the [Contributing Guide](https://github.com/guard/guard/blob/master/CONTRIBUTING.md#development).

## Releasing

### Prerequisites

* You must have commit rights to the GitHub repository.
* You must have push rights for rubygems.org.

### How to release

1. Determine which would be the correct next version number according to [semver](http://semver.org/).
1. Update the version in `./lib/guard/version.rb`.
1. Commit the version in a single commit, the message should be "Bump VERSION to X.Y.Z".
1. Push and open a pull request.
1. Once CI is green, merge the pull request.
1. Pull the changes locally and run `bundle exec rake release:full`; this will tag, push to GitHub, publish to rubygems.org, and publish the [release notes](https://github.com/guard/guard/releases) .

### Author

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](https://twitter.com/thibaudgg))

### Core Team

* R.I.P. :broken_heart: [Michael Kessler](https://github.com/netzpirat).
* [Rémy Coutable](https://github.com/rymai).
* [Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](https://twitter.com/thibaudgg), [thibaud.gg](https://thibaud.gg/)).

### Contributors

[https://github.com/guard/guard/graphs/contributors](https://github.com/guard/guard/graphs/contributors)
