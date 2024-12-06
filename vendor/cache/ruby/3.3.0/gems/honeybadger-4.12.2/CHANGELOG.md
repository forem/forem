# Change Log
All notable changes to this project will be documented in this file. See [Keep a
CHANGELOG](http://keepachangelog.com/) for how to update this file. This project
adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [4.12.2] - 2022-08-15
### Fixed
- Fix a bug where the auto-detected revision is blank instead of nil
- Fix inadvertent creation of invalid sessions (#441)

## [4.12.1] - 2022-04-01
### Fixed
- Fix Lambda plugin: support Ruby <2.5 (#428)

## [4.12.0] - 2022-03-30
### Added
- Added `hb_wrap_handler` to automatically capture AWS Lambda handler errors

### Fixed
- Change `:exception_message` key name to just `:exception` for error breadcrumb metadata.

## [4.11.0] - 2022-02-15
### Fixed
- Allow special characters in tags. Also support space-delimited tags:
  "one two three" and "one, two, three" are equivalent

## [4.10.0] - 2022-01-19
### Added
- Add more items to the default config file

### Fixed
- Fix a Ruby 3.1 bug that breaks regexp classes in honeybadger.yml (#418)

## [4.9.0] - 2021-06-28
### Fixed
- Replaced fixed number for retries in Sidekiq Plugin with Sidekiq::JobRetry constant
- Properly set environment in deployment tracking (#404, @stmllr)

### Added
- Added 'ActionDispatch::Http::MimeNegotiation::InvalidType' (Rails 6.1) to
  default ignore list. (#402, @jrochkind)

## [4.8.0] - 2021-03-16
### Fixed
- Suppress any error output from the `git rev-parse` command. ([#394](https://github.com/honeybadger-io/honeybadger-ruby/pull/394))

### Added
- Support deployment tracking in code (#397, @danleyden)

## [4.7.3] - 2021-02-10
### Fixed
- Don't enable Lambda plugin in non-Lambda execution environments

## [4.7.2] - 2020-08-17
### Fixed
- Remove usage of `ActiveRecord::Base.connection` (thanks @jcoyne for testing)
- Check for UTF-8 in ActiveRecord breadcrumb exclusion filter

## [4.7.1] - 2020-08-11
### Fixed
- ActiveRecord SQL Breadcrumb event pulls adapter from supplied connection,
  allowing for multiple databases.
- Fix Rails deprecation of `ActionDispatch::ParamsParser::ParseError`
- Deal with invalid UTF-8 byte sequences during SQL obfuscation
- Fix Ruby 2.7 deprecation notice in sql.rb

## [4.7.0] - 2020-06-02
### Fixed
- Alias `Notice#controller=` as `Notice#component=`
- Fix Rails 6.1 deprecation warning with `ActiveRecord::Base.connection_config`
- Fix agent where breadcrumbs.enabled = true and local_context = true

### Added
- Add `honeybadger_skip_rails_load` Capistrano option to skip rails load on
  deployment notification (#355) -@NielsKSchjoedt

## [4.6.0] - 2020-03-12
### Fixed
- Fixed issue where Sidekiq.attempt_threshold was triggering 2 attempts ahead
  of the setting
- Dupe notify opts before mutating (#345)

### Changed
- Breadcrumbs on by default
- Added Faktory plugin -@scottrobertson

## [4.5.6] - 2020-01-08
### Fixed
- Fix remaining Ruby 2.7 deprecation warnings

## [4.5.5] - 2020-01-06
### Fixed
- Replace empty `Proc.new` with explicit block param to suppress warnings
  in Ruby 2.7

## [4.5.4] - 2019-12-09
### Fixed
- Re-released to remove vendor cruft

## [4.5.3] - 2019-12-09
### Fixed
- Include Context in Notices for failed Resque jobs

## [4.5.2] - 2019-10-09
### Changed
- Added parameter filtering to breadcrumb metadata (#329)

### Added
- Added `lambda` plugin which forces sync mode (to make sure that we are not
  sending notices in another thread) and adds extra lambda details to the
  Notice. (honeybadger-ruby-internal#1)

## [4.5.1] - 2019-08-13
### Fixed
- Logging breadcrumbs will not crash anymore when logging is done using a block
  form. -@Bajena
- When `breadcrumbs` are enabled ensure we call the original `Logger#add` with
  the original arguments -@JanStevens

## [4.5.0] - 2019-08-05
### Changed
- Default `max_queue_size` has been reduced from 1000 to 100.

### Added
- Added `Notice#causes`, which allows cause data to be mutated in
  `before_notify` callbacks (useful for filtering purposes).
- Added `Notice#cause=`, which allows the cause to be changed or disabled
  in `before_notify` callbacks.
- Added extra shutdown logging.

### Fixed
- `Honeybadger.notify(exception, cause: nil)` will now prevent the cause from
  being reported.
- When throttled, queued notices will be discarded during shutdown.

## [4.4.2] - 2019-08-01
### Fixed
- Handle ActiveSupport::Notifications passing nil started or finished time
  -@pcreux

## [4.4.1] - 2019-07-30
### Fixed
- Allow non-strings to be passed to breadcrumbs logger

## [4.4.0] - 2019-07-24
### Added
- Added the ability to store and send Breadcrumbs along with the notice.
  Breadcrumbs are disabled by default in this version so they must be enabled
  via the config (option `breadcrumbs.enabled`) to work.

## [4.3.1] - 2019-05-30
### Fixed
- Add Rails 6 RC1 Support

## [4.3.0] - 2019-05-17
### Added
- Send a value for action when reporting a component for Sidekiq jobs -@stympy

## [4.2.2] - 2019-04-25
### Fixed
- Fix a bug where some non-standard backtraces could not be parsed, resulting in
  an error when sending error reports. Backtraces are now explicitly converted
  to arrays, and lines are converted to strings.
- Fix a typo in throttle log message. -@mobilutz

## [4.2.1] - 2019-02-01
### Fixed
- Fix #301 - before_notify hooks are overridden on subsequent
  `Honeybadger.configure` calls.
- Revert "Get the right controller / action name in Rails, when using an
  exception app for custom error pages."

## [4.2.0] - 2019-01-31
### Changed
- Issue a Notification from a Sidekiq job when either the `sidekiq.attempt_threshold` is reached OR if the job defined retry threshold is reached, whichever comes first. -@mstruve
- Updated supported Ruby/Rails versions (MRI >= 2.3.0, JRuby >= 9.2, Rails >= 4.2)
  https://docs.honeybadger.io/ruby/gem-reference/supported-versions.html

### Added
- Get the right controller / action name in Rails, when using an exception app for custom error pages. -@fernandes

## [4.1.0] - 2018-10-16
### Added
- Added flag `--skip-rails-load` to cli commands for optionally skipping Rails initialization when running from a Rails root.

### Fixed
- Added missing Backend::Server#check_in specs
- Fix a memory leak in the worker queue (jruby)

## [4.0.0] - 2018-08-21
### Added
- Added `before_notify` hooks to be defined, this allows setting up of multiple
  hooks which will be invoked with a `notice` before a `notice` is sent. Each
  `before_notify` hook MUST be a `callable` (lambda, Proc etc,) with an arity of 1.
- Added the ability to halt notices in callbacks using `notice.halt!`
- Make essential attributes on Notice writable:
  ```ruby
  Honeybadger.configure do |config|
    config.before_notify do |notice|
      notice.api_key = 'custom api key',
      notice.error_message = "badgers!",
      notice.error_class = 'MyError',
      notice.backtrace = ["/path/to/file.rb:5 in `method'"],
      notice.fingerprint = 'some unique string',
      notice.tags = ['foo', 'bar'],
      notice.context = { user: 33 },
      notice.controller = 'MyController',
      notice.action = 'index',
      notice.parameters = { q: 'badgers?' },
      notice.session = { uid: 42 },
      notice.url = "/badgers",
    end
  end
  ```

### Fixed
- Ignore SIGTERM SignalExceptions.

### Removed
- Removed Notice#[]

### Changed
- The public method `Notice#backtrace` is now exposed as the raw Ruby
  backtrace instead of an instance of `Honeybadger::Backtrace` (a private
  class).

  Before:
  ```ruby
  notice.backtrace # => #<Honeybadger::Backtrace>
  ```

  After:
  ```ruby
  notice.backtrace # => ["/path/to/file.rb:5 in `method'"]
  ```
- `notice[:context]` now defaults to an empty Hash instead of nil.

  Before:
  ```ruby
  notice[:context] # => nil
  ```

  After:
  ```ruby
  notice[:context] # => {}
  ```
- The public method `Notice#fingerprint` now returns the original
  String which was passed in from the `:fingerprint` option or the
  `exception_fingerprint` callback, not a SHA1 hashed value. The value is
  still hashed before sending through to the API.
- The public method `Honeybadger.exception_filter` has been deprecated in favor
  of `before_notify`:
  ```ruby
  Honeybadger.configure do |config|
    config.before_notify do |notice|
      notice.halt!
    end
  end
  ```
- The public method `Honeybadger.exception_fingerprint` has been deprecated in favor
  of `before_notify`:
  ```ruby
  Honeybadger.configure do |config|
    config.before_notify do |notice|
      notice.fingerprint = 'new fingerprint'
    end
  end
  ```
- The public method `Honeybadger.backtrace_filter` has been deprecated in favor
  of `before_notify`:
  ```ruby
  Honeybadger.configure do |config|
    config.before_notify do |notice|
      notice.backtrace.reject!{|x| x =~ /gem/}
    end
  end
  ```

### Removed
- The `disabled` option is now removed, Use the `report_data` option instead.

## [3.3.1] - 2018-08-02
### Fixed
- Fix synchronous throttling in shoryuken

## [3.3.0] - 2018-01-29
### Changed
- Use prepend to add Sidekiq Middleware to fix context getting cleared.
- Add `Rack::QueryParser::ParameterTypeError` and
  `Rack::QueryParser::InvalidParameterError` to default ignore list.

### Fixed
- Use a unique route name in rails to avoid name conflicts.
- Fix `at_exit` callback being skipped in rails apps with a sinatra dependency.

## [3.2.0] - 2017-11-27
### Changed
- Objects which explicitly alias `#to_s` to `#inspect` (such as `OpenStruct`) are
  now sanitized. `'#<OpenStruct attribute="value">'` becomes `'#<OpenStruct>'`.
  If you pass the value of `#inspect` (as a `String`) directly to Honeybadger (or
  return it from `#to_honeybadger`), the value will not be sanitized.
- We're now using `String(object)` instead of `object.to_s` as the last resort
  during sanitization.

### Added
- The exception cause may now be set using an optional `:cause` option when
  calling `Honeybadger.notify`. If not present, the exception's cause will be
  used, or the global `$!` exception if available.
- Any object can now act as context using the `#to_honeybadger_context` method.
  The method should have no arguments and return a `Hash` of context data.
  Context from exceptions which define this method will automatically be
  included in error reports.
- Final object representations in Honeybadger (normally the value of `#to_s`
  for unknown types) can be changed by defining the `#to_honeybadger` method. If
  the method is defined, the return value of that method will be sent to Honeybadger
  instead of the `#to_s` value (for context values, local variables, etc.).
- `'[RAISED]'` is returned when `object.to_honeybadger` or `String(object)` fails.
- Added `Honeybadger.check_in` method which allows performing check ins from ruby.

### Fixed
- We no longer use "/dev/null" as the default log device as it doesn't exist on
  Windows.
- Logs when reporting errors in development mode now mention that the error wasn't
  *actually* reported. :)
- Support new Sidekiq job params key.
- Move at_exit callback to an appropriate place for sinatra apps, so that it does
  not prematurely stop honeybadger workers.
- `BasicObject`, which previously could not be serialized, is now serialized as
  `"#<BasicObject>"`.

## [3.1.2] - 2017-04-20
### Fixed
- Fixed a bug in the Resque plugin which prevented error reports from being
  sent. The issue was that the Resque's callbacks were executed in an unexpected
  order which caused the queue to be flushed before error notification instead
  of after.

## [3.1.1] - 2017-04-13
### Fixed
- `honeybadger deploy` cli command now reads default environment from
  honeybadger.yml/environment variable.
- Fixed a conflict with the web-console gem.

## [3.1.0] - 2017-03-01
### Changed
- Exceptions encountered while loading/evaluating honeybadger.yml are now raised
  instead of logged.

### Added
- Friendlier backtraces for exceptions originating in honeybadger.yml.
- Notify errors in Shoryuken batches -@phstc

### Fixed
- Rails environment is now loaded when running `honeybadger` cli from a Rails
  root. This fixes an issue where programmatic configuration from Rails was not
  loaded.
- Fixed logger isn't being overridden properly when configuring with
  Honeybadger.configure -@anujbiyani

## [3.0.2] - 2017-02-16
### Fixed
- Fixed a bug caused by an interaction with the semantic\_logger gem.

## [3.0.1] - 2017-02-10
### Fixed
- Fixed a bug which caused a NoMethodError (undefined method \`start_with?') when
  Rack env contained non-string keys.

## [3.0.0] - 2017-02-06
### Added
- You may now require 'honeybadger/ruby' instead of 'honeybadger' to get the
  agent without the integrations (no railtie, plugins or monkey patching).
- You can now create multiple instances of the Honeybadger agent with different
  configurations (many classes in the library can be composed).
- `Honeybadger.configure` works again -- use it to configure the library from
  Ruby! (we still default to honeybadger.yml in our installer)
- Our test suite is now leaner and meaner (which means we can add new features
  faster). Reduced typical build times from up to 2 minutes to 20 seconds.
- We've rebuilt the CLI from scratch. The new CLI features super verbose error
  messages with (hopefully) helpful suggestions, some new commands, and better
  framework detection in the `install` and `test` commands.
- Use `honeybadger exec your_command` from the command line to report the error
  when the command fails due to a non-zero exit status or standard error output.
  (Use it to report failures in cron!) See `honeybadger help exec`.
- Use `honeybadger notify` from the command line to report custom errors to
  Honeybadger. See `honeybadger help notify`.
- ~/honeybadger.yml is now a default config path for the CLI and standalone-ruby
  installations.
- `Honeybadger.notify` now converts arguments which are not `Exception` or
  `Hash` types to strings and assigns them as the error message. Example:
  `Honeybadger.notify("Something went wrong")`.
- The currently deployed git revision is now detected automatically and sent
  with error reports.

### Changed
- `Honeybadger.start` has been deprecated and has no effect.
- We've changed some of the underlying code of the library. If you depend on
  internal APIs (such as thread local variable names or any functions not marked
  public in the code comments) then you may need to update your code. If you are
  developing 3rd-party integrations with our gem [let us
  know](https://github.com/honeybadger-io/honeybadger-ruby/issues) so that we can
  work with you to build the public APIs you need.
- All Rack middleware no longer require an argument (which used to be a
  `Honeybadger::Config` instance) when using them. They now default to the
  global agent and accept an optional argument which expects an alternate
  `Honeybadger::Agent` instance.
- The *plugins.skip* config option has been renamed to *skipped_plugins*.
- The *sidekiq.use_component* config option is now `true` by default. To get the
  old behavior, set it to `false`. When enabled, the Sidekiq plugin will
  automatically set the component to the class of the job, which helps with
  grouping.
- The `request.filter_keys` option now includes partial matches: with the filter
  value "password", keys such as "password" and "otherpassword" will be
  filtered.
- CGI variables are now whitelisted when sending the Rack environment to
  Honeybadger to prevent sensitive data leakage.
- `Honeybadger.notify` now raises an exception in development mode when called
  without the required arguments. It logs outside of development and continues
  to send a generic error report.

### Removed
- Ruby 1.9.3 and 2.0.x are no longer supported.
- `Honeybadger.notify_or_ignore` has been removed. Use `Honeybadger.notify(e)`
  and `Honeybadger.notify(e, force: true)` (to skip ignore filters).
- The CLI command `honeybadger config` has been removed.
- All deprecated Rails controller methods (from version 1.x) have been removed.
- The deprecated `Honeybadger::Rack::MetricsReporter` middleware has been
  removed.

### Fixed
- Arrays are no longer compacted during sanitization (`nil` values will be sent
  as they originally appeared).
- Resque plugin now reports `Resque::DirtyExit` exceptions.

## [2.7.2] - 2016-12-12
### Fixed
- Pass whole exception to `notify_or_ignore` (includes causes). -@CGamesPlay

## [2.7.1] - 2016-11-16
### Fixed
- Fix a Sinatra bug where `RACK_ENV` default was not used as default env.
- Fixed an error when accessing notice request data from `exception_fingerprint`
  callback.

## [2.7.0] - 2016-10-20
### Added
- Support Sinatra 2.0.
- Source snippets are now sent for every line of the backtrace.

### Changed
- Sunset performance metrics. See
  http://blog.honeybadger.io/sunsetting-performance-metrics/
- Backtraces are now limited to a maximum of 1000 lines.

## [2.6.1] - 2016-08-24
### Added
- shoryuken plugin. -@ivanvc

### Fixed
- Handle `Errno::ENETUNREACH` error when contacting server. -@tank-bohr
- Remove `ActionDispatch::Http::Headers` from trace payload (fixes `IOError`
  when JSON encoding traces in Rails 5).
- Fix "`invoke("git:set_current_revision")` already invoked" warning in
  Capistrano 3.6.

## [2.6.0] - 2016-04-22
### Added
- Automatically report unhandled exceptions at exit.
- Add `Honeybadger.get_context` method. -@homanchou

### Changed
- Filter Authorization header (HTTP\_AUTHORIZATION) by default.

### Fixed
- Always convert to string when sanitizing strings.
- Fix potential performance issue due to and `ensure` block. See #186.

## [2.5.3] - 2016-03-10
### Fixed
- Squashed a bug where the wrong source extract was sent for some instances of
  `ActionView::Template::Error`.

## [2.5.2] - 2016-03-08
### Fixed
- Allow plugin names in config to be symbols or strings (#177).
- Fix bug in resque-retry logic. -@davidguthu

## [2.5.1] - 2016-02-22
### Fixed
- Fix bug in resque-retry logic. -@davidguthu

## [2.5.0] - 2016-02-19
### Added
- Configuration option max\_queue_size for maximum worker queue size.
- Add `resque.resque_retry.send_exceptions_when_retrying` config option.
  -@davidguthu

## [2.4.1] - 2016-02-04
### Fixed
- Never send traces or metrics when disabled by plan or config.

## [2.4.0] - 2016-02-02
### Added
- [Sucker Punch](https://github.com/brandonhilkert/sucker_punch) support

## [2.3.3] - 2016-01-06
### Fixed
- Fixed a bug which caused a Passenger-related error message when booting a
  heroku console.

## [2.3.2] - 2015-12-15
### Fixed
- Be stricter when sanitizing recursive objects (allow only `Hash`, `Array`,
  `Set`).  This fixes a bug where some gems (such as the dropbox gem)
  monkeypatch `#to_hash` on `Array`.

## [2.3.1] - 2015-11-20
### Fixed
- Handle invalid utf8 in ActiveRecord SQL queries.

## [2.3.0] - 2015-11-12
### Added
- Rails 5 support.
- Support overriding TTY behavior in rake reporter.

### Fixed
- Capistrano 3 `undefined method `verbosity'` bugfix.
- Fixed "uninitialized constant Set" error when Set is not previously required.

## [2.2.0] - 2015-10-29
### Added
- Added a config option to automatically set the component to the class name of the
  Sidekiq job where an error originated. Causes errors to be grouped by worker
  in addition to class name/location.

### Fixed
- Always refresh capistrano revision during deploy notification.
- Support capistrano-chruby. -Kyle Rippey
- Send the wrapped class name for Sidekiq traces when using a wrapper such as
  ActiveJob.
- Performance tuning for Sidekiq plugin.

## [2.1.5] - 2015-09-23
### Fixed
- Apply parameter filters to local variables.

## [2.1.4] - 2015-09-02
### Fixed
- Support windows paths when loading plugins. -@aharpervc

## [2.1.3] - 2015-07-24
### Added
- Don't send empty local_variables in payload when disabled.
- Better logging of reason when API requests are denied.
- Truncate long queries in traces rather than tossing them.

### Fixed
- Missing vendor libs.

## [2.1.2][yanked]

## [2.1.1] - 2015-07-15
### Added
- Update heroku cli deprecations. -@adamkuipers
- Don't insert middleware if they're disabled. -Bradley Priest
- Don't send RAW_POST_DATA.
- Filter HTTP_COOKIE in request cgi_data. -Sam McTaggart
- Support for extracting the correct component & action for Rails Active Jobs
  (previously all Active Jobs where reported as
  'ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper'). -Panos Korros

### Fixed
- Fix breakage relating to Exceptions containing a :cause attribute which is not
  itself an Exception. -Gabe da Silveira

## [2.1.0] - 2015-06-04
### Added
- Add events to instrumented traces (i.e. in background jobs).
- Restart workers once per hour when shutdown due to 40x.
- Send request data with traces.
- Support Resque natively.
- Configure sidekiq.attempt_threshold to suppress notifications until retry
  threshold is reached.
- Add exceptions.unwrap to config.

### Changed
- Trim all sanitized strings to 2k.
- Ditch per-controller metrics and add render_partial event to traces. -Benjamin Curtis
- Exit with 1 from deploy command when request fails but ignore the failures in
  the capistrano task.
- Update default ignored exceptions to include the latest Rails rescue
  responses. (see issue #107)
- Exceptions with the same type but caused within different delayed jobs are not
  grouped together. They have their component and action set so that the
  application class name and excecuted action is displayed in the UI.  -Panos
  Korros
- All events logged within a delayed_job even those logged by Honeybadger.notify
  inherit the context of the delayed job and include the job_id, attempts,
  last_error and queue. -Panos Korros

### Fixed
- Allow API key to be overridden from `Honeybadger.notify`.
- Fix a tracing issue with net/http requests.
- Disable local variables when BetterErrors is detected.
- Prevent Sinatra from using the same middleware more than once and add
  sinatra.enabled setting (default true) to disable auto-initialization
  of Sinatra.
- Catch Errno::ENFILE when reading system stats. -Dmitry Polushkin
- Use explicit types for config options when casting from ENV.

## [2.0.12] - 2015-04-27
### Fixed
- Fix bug when processing source extract for action_view templates.

## [2.0.11] - 2015-04-02
### Fixed
- Don't access secrets before Rails initialization.
- Fix a bug which introduced a hard-dependency on Rack.

## [2.0.10] - 2015-03-24
### Added
- Add support for honeybadger_user with Capistrano 2. -Nathan Fixler

### Fixed
- Fix a bug in ping where JSON was double-quoted.

## [2.0.9] - 2015-03-15
### Fixed
- Fixed a bug introduced in v2.0.8 which applied params filters to backtrace.
- Fail gracefully when honeybadger.yml is empty or invalid.

## [2.0.8] - 2015-03-11
### Added
- Include full backtrace when logging worker exceptions.
- Always send a test notice on install.
- Send the id of the current process with error reports.

### Fixed
- Handle bad encodings in exception payloads.

## [2.0.7][yanked] - 2015-03-11

## [2.0.6] - 2015-02-16
### Fixed
- Don't sub partial project root in backtrace lines.

## [2.0.5] - 2015-02-12
### Added
- Merge exceptions.ignore config values with default ignored exception class
  names and add exceptions.ignore_only option to override.

## [2.0.4] - 2015-02-10
### Added
- Support for capistrano-rbenv gem in Capistrano task. -Chris Gunther

## [2.0.3] - 2015-02-10
### Fixed
- Support for capistrano-rvm gem in Capistrano task. -Kyle Rippey
- Don't require honeybadger.yml to be writable when reading.

## [2.0.2] - 2015-02-04
### Fixed
- Detect ActionDispatch::TestProcess being included globally, fix issue locally,
  warn the user.
- Fix a nil logger bug when a config error occurs.

## [2.0.1] - 2015-01-30
### Fixed
- Don't instrument metrics and traces in Rails when features are not available
  on account.
- Don't send error reports when disabled via configuration.
