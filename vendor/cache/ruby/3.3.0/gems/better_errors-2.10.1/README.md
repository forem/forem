[![Build Status](https://github.com/BetterErrors/better_errors/workflows/CI/badge.svg?event=push&branch=master)](https://github.com/BetterErrors/better_errors/actions?query=branch%3Amaster)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/6bc3e7d6118d47e6959b16690b815909)](https://www.codacy.com/app/BetterErrors/better_errors?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=BetterErrors/better_errors&amp;utm_campaign=Badge_Grade)
[![Test Coverage](https://coveralls.io/repos/github/BetterErrors/better_errors/badge.svg?branch=master)](https://coveralls.io/github/BetterErrors/better_errors?branch=master)
[![Gem Version](https://img.shields.io/gem/v/better_errors.svg)](https://rubygems.org/gems/better_errors)

# Better Errors

Better Errors replaces the standard Rails error page with a much better and more useful error page. It is also usable outside of Rails in any Rack app as Rack middleware.

![screenshot of Better Errors in action](https://i.imgur.com/6zBGAAb.png)

## Features

For screenshots of these features, [see the wiki](https://github.com/BetterErrors/better_errors/wiki).

* Full stack trace
* Source code inspection for all stack frames (with highlighting)
* Local and instance variable inspection
* Live shell (REPL) on every stack frame
* Links directly to the source line in your editor
* Useful information in non-HTML requests

## Installation

Add this to your Gemfile:

```ruby
group :development do
  gem "better_errors"
  gem "binding_of_caller"
end
```

[`binding_of_caller`](https://github.com/banister/binding_of_caller) is optional, but is necessary to use Better Errors' advanced features (REPL, local/instance variable inspection, pretty stack frame names).

_Note: If you discover that Better Errors isn't working - particularly after upgrading from version 0.5.0 or less - be sure to set `config.consider_all_requests_local = true` in `config/environments/development.rb`._

### Optional: Set `EDITOR`

For many reasons outside of Better Errors, you should have the `EDITOR` environment variable set to your preferred
editor.
Better Errors, like many other tools, will use that environment variable to show a link that opens your
editor to the file and line from the console.

By default the links will open TextMate-protocol links.

To see if your editor is supported or to set up a different editor, see [the wiki](https://github.com/BetterErrors/better_errors/wiki/Link-to-your-editor).

### Optional: Set `BETTER_ERRORS_INSIDE_FRAME`

If your application is running inside of an iframe, or if you have a Content Security Policy that disallows links
to other protocols, the editor links will not work.

To work around this set `BETTER_ERRORS_INSIDE_FRAME=1` in the environment, and the links will include `target=_blank`,
allowing the link to open regardless of the policy.

_This works because it opens the editor from a new browser tab, escaping from the restrictions of your site._
_Unfortunately it leaves behind an empty tab each time, so only use this if needed._

## Security

**NOTE:** It is *critical* you put better\_errors only in the **development** section of your Gemfile.
**Do NOT run better_errors in production, or on Internet-facing hosts.**

You will notice that the only machine that gets the Better Errors page is localhost, which means you get the default error page if you are developing on a remote host (or a virtually remote host, such as a Vagrant box).
Obviously, the REPL is not something you want to expose to the public, and there may be sensitive information available in the backtrace.

For more information on how to configure access, see [the wiki](https://github.com/BetterErrors/better_errors/wiki/Allowing-access-to-the-console).

## Usage

If you're using Rails, there's nothing else you need to do.

### Using without Rails.

If you're not using Rails, you need to insert `BetterErrors::Middleware` into your middleware stack, and optionally set `BetterErrors.application_root` if you'd like Better Errors to abbreviate filenames within your application.

For instructions for your specific middleware, [see the wiki](https://github.com/BetterErrors/better_errors/wiki/Non-Rails-frameworks).

### Plain text requests

Better Errors will render a plain text error page  when the request is an
`XMLHttpRequest` or when the `Accept` header does *not* include 'html'.

### Unicorn, Puma, and other multi-worker servers

Better Errors works by leaving a lot of context in server process memory.
If you're using a web server that runs multiple "workers" it's likely that a second
request (as happens when you click on a stack frame) will hit a different
worker.
That worker won't have the necessary context in memory, and you'll see
a `Session Expired` message.

If this is the case for you, consider turning the number of workers to one (1)
in `development`. Another option would be to use Webrick, Mongrel, Thin,
or another single-process server as your `rails server`, when you are trying
to troubleshoot an issue in development.

### Changing the link to your editor

Better Errors includes a link to your editor for the file and line of code that is being shown.
By default, it uses your environment to determine which editor should be opened.
See [the wiki for instructions on configuring the editor](https://github.com/BetterErrors/better_errors/wiki/Link-to-your-editor).


## Set maximum variable size for inspector.

```ruby
# e.g. in config/initializers/better_errors.rb
# This will stop BetterErrors from trying to render larger objects, which can cause
# slow loading times and browser performance problems. Stated size is in characters and refers
# to the length of #inspect's payload for the given object. Please be aware that HTML escaping
# modifies the size of this payload so setting this limit too precisely is not recommended.  
# default value: 100_000
BetterErrors.maximum_variable_inspect_size = 100_000
```

## Ignore inspection of variables with certain classes.

```ruby
# e.g. in config/initializers/better_errors.rb
# This will stop BetterErrors from trying to inspect objects of these classes, which can cause
# slow loading times and unnecessary database queries. Does not check inheritance chain, use
# strings not constants.
# default value: ['ActionDispatch::Request', 'ActionDispatch::Response']
BetterErrors.ignored_classes = ['ActionDispatch::Request', 'ActionDispatch::Response']
```

## Get in touch!

If you're using better_errors, I'd love to hear from you. Drop me a line and tell me what you think!

## Development

After checking out the repo, run `bundle install` to install the basic dependencies.

You can run the tests with the simplest set of dependencies using:

```rb
bundle exec rspec
```

To run specs for each of the dependency combinations, run:

```rb
bundle exec rake test:all
```

You can run specs for a specific dependency combination using:

```rb
BUNDLE_GEMFILE=gemfiles/pry09.gemfile bundle exec rspec
```

On CI, the specs are run against each gemfile on each supported version of Ruby.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
