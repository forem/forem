v2.1.0 (2020-01-13)
--------------------------------------------------------------------------------

*   Update version to v2.1.0 final
    Tom Scott

*   Test against most recent versions of Ruby
    Tom Scott

*   Update gemspec to remove rubyforge_project

    It is deprecated or removed already

    Original warning message:
    Gem::Specification#rubyforge_project= is deprecated with no replacement. It will be removed on or after 2019-12-01.
    PikachuEXE

*   back tests to original state
    Alexey Vasiliev

*   Fix redis-rack for rack 2.0.8, small improvements
    Alexey Vasiliev

*   Fix redis-rack for rack 2.0.8, fix generate_unique_sid
    Alexey Vasiliev

*   Fix redis-rack for rack 2.0.8
    Alexey Vasiliev

*   v2.1.0.pre: Update Rack Session API, drop support for Rack 1.0
    Tom Scott

v2.0.6
--------------------------------------------------------------------------------

*   v2.0.6: Prevent Connection Pool from passing nil options
    Tom Scott

*   Make bundler dependency more permissive to support future ruby versions
    Tom Scott

*   Drop support for Rack v1
    Tom Scott

*   Update Rack::Session API Compatibility

    The latest version of Rack [deprecated subclassing Rack::Session::ID](https://github.com/rack/rack/blob/master/lib/rack/session/abstract/id.rb#L412-L419),
    replacing it instead with `Rack::Session::Persisted`. Update the method
    implementations in this gem to support the new API. Shoutouts to @onk
    for actually writing this code, we're pulling it in from his fork.
    Tom Scott

*   Automatically assign issues to @tubbo when they are created
    Tom Scott

*   Automatically release to RubyGems when new tags are pushed to GitHub
    Tom Scott

*   Raise Error when `:redis_store` is Incorrect Type

    Passing an object that isn't a `Redis::Store` into the session storage
    configuration can cause errors when methods are called with more
    arguments than the default Redis client can handle. These additional
    arguments are used by `Rack::Session::Redis` to configure the key
    namespace and TTL globally in the main configuration, and pass them down
    to `Redis::Store` to be appended to the key. An `ArgumentError` will now
    be thrown when a `:redis_store` is of a type that isn't a `Redis::Store`
    (or a subclass thereof).

    Resolves #46
    Tom Scott

*   Add code owners
    Tom Scott

*   Do not provide nil values for missing connection pool options

    Fixes #44
    Jake Goulding

v2.0.5
--------------------------------------------------------------------------------

*   v2.0.5 release
    Tom Scott

*   add spec to validate blank sessions are not stored in redis
    mstruve

*   dont store a blank session in redis
    mstruve

*   Add documentation for options
    Daniel M Barlow

v2.0.4
--------------------------------------------------------------------------------

*   Release 2.0.4
    Tom Scott

*   Remove .ruby-version
    Tom Scott

*   Remove rake, appraisal from gemspec executables

    The contents of the bin directory are binstubs to assist development.
    They are not intended to be shipped with the gem itself. This commit
    updates the gemspec to ensure that they are not exposed to rubygems as
    executables for redis-rack, which will fix conflicts with the legitimate
    rake and appraisal executables provided by those other gems.
    Matt Brictson

v2.0.3
--------------------------------------------------------------------------------

*   v2.0.3: Avoid mutex locking with global option
    Tom Scott

*   Restore default_options in #generate_unique_sid
    Tom Scott

*   Refactor connection_pool code

    Adds a `Redis::Rack::Connection` object for handling the instantiation
    of a `Redis::Store` or a `ConnectionPool` if pool configuration is
    given. Restores the purpose of `Rack::Session::Redis` to only implement
    the session ID abstract API provided by Rack.
    Tom Scott

*   Rename :use_global_lock option to :threadsafe to match Rails
    Garrett Thornburg

*   Use mocha mocks to assert the mutex is never locked
    Garrett Thornburg

*   Allow redis-store v1.4
    Shane O'Grady

*   Create a :use_global_lock option that avoids the global lock
    Garrett Thornburg

*   Rake task for running all tests on all gem versions
    Tom Scott

*   Install Appraisal so we can test against multiple versions of Rack
    Tom Scott

v2.0.2
--------------------------------------------------------------------------------

*   v2.0.2: Resolve regression forcing Rack 2.x and above
    Tom Scott

v2.0.1
--------------------------------------------------------------------------------

*   v2.0.1: Relax gem dependencies
    Tom Scott

*   smoothen redis-store dependency
    Mathieu Jobin

*   Drop support for Rubinius 1.9 mode

    1.9.x is EOL in MRI Ruby Land, and Rubinius 1.9 mode isn't really used
    much anymore. This should make the builds pass again.
    Tom Scott

*   Update README.md (#20)
    Nicolas

*   Remove jruby 1.9 mode from the build matrix
    Tom Scott

*   Remove test because why
    Tom Scott

v2.0.0
--------------------------------------------------------------------------------

*   v2.0: Drop support for Ruby below 2.2 (thanks @connorshea)

    Fixes #17, major shoutouts to @connorshea for getting this off the
    ground. This also edits the CI config to drop support for older Ruby
    versions.
    Tom Scott

*   Fix gem dependency versions
    Tom Scott

*   v2.0.0.pre Add support for Rails 5 and Rack 2.
    Tom Scott

*   v2.0.0: Upgrade to Rack 2.0

    This release includes some backwards-incompatible changes that pertain
    to Rails' upgrade to Rack 2.x.
    Tom Scott

*   Update README
    Tom Scott

*   Fix readme
    Tom Scott

*   travis.yml add Ruby 2.3.0
    shiro16

*   add 2.1 and 2.2 rubies to travis
    Marc Roberts

*   Remove support for Ruby 1.9
    Marc Roberts

*   Loosen dependancy on Rack to allow 1.5 and 2.x

    Rails 5 beta requires Rack 2.x and this gem is unusable unless can use Rack 2.x
    Marc Roberts

*   Update README.md
    Ryan Bigg

*   add support for ConnectionPool
    Roman Usherenko

*   Introduce redis_store option (closes #1)
    Kurakin Alexander

*   Atomically lock session id and implement skip support.
    W. Andrew Loe III

v1.5.0
------

*   Enable CI
    Luca Guidi

*   Update README.md
    Luca Guidi

*   Moved back from jodosha/redis-store
    Luca Guidi

*   Moved
    Luca Guidi
