v5.2.0 (2020-01-13)
--------------------------------------------------------------------------------

*   Require latest version of redis-rack
    Tom Scott

*   Update version to v5.2.0 final
    Tom Scott

*   Fix for rack 2.0.8 (#28)

    * Fix for rack 2.0.8
    * add new redis-rack for tests
    * add new ruby 2.7 for tests
    Alexey Vasiliev

*   v5.2.0.pre: Support Signed/Encrypted Cookies
    Tom Scott

*   Update README with info about signed cookies
    Tom Scott

*   Support Signed and Encrypted Cookie Storage (#27)

    With the `:signed` option passed into the Redis session store, you can
    now ensure that sessions will be set up in the browser using a
    signed/encrypted cookie. This prevents user tampering by changing their
    session ID or the data within the cookie.

    Closes #21
    Tom Scott

v5.1.0
--------------------------------------------------------------------------------

*   Add appraisal to test on multiple versions of Rails (#18)

    Update the build configuration to exclude older versions we no longer support and use Appraisal to test against multiple gemfiles/rubies in CI.

    * Remove old gemfiles
    * Update appraisal gemfiles
    * Exclude some builds
    * Install bundler on older versions of Ruby
    * Prevent updating bundler to a non-compatible version
    * Remove lockfiles from the repo
    * Drop support for old versions of Rails & Ruby
    * Automatically assign issues to @tubbo when they are created
    Tom Scott

*   Reduce build scope to only support Rails 5 & 6
    Tom Scott

*   v5.1.0: Support Rails 6
    Tom Scott

*   Bump max version constraint on actionpack (#25)

    This change allows this gem to work with Rails 6.
    Arjun Radhakrishnan

*   Fix build
    Tom Scott

*   README: Use SVG badges
    Olle Jonsson

*   Gemspec: Drop EOL'd property rubyforge_project
    Olle Jonsson

*   Loosen Bundler dependency
    Tom Scott

*   Update testing matrix
    Tom Scott

*   Automatically release to RubyGems when new tags are pushed to GitHub
    Tom Scott

*   Add code owners
    Tom Scott

*   Clarify usage of gem in the README
    Tom Scott

*   Fix rails 4 build failure
    Tom Scott

*   Don't always use local testing gem
    Tom Scott

v5.0.2
--------------------------------------------------------------------------------

*   v5.0.2: Loosen dependencies to work with new minor redis-store versions
    Tom Scott

*   Update class name in README
    Tom Scott

*   Loosen redis-store dependency
    Tom Scott

*   Update tests to remove deprecation warnings
    Tom Scott

*   Remove testing code from Gemfile
    Tom Scott

v5.0.1
--------------------------------------------------------------------------------

*   Release v5.0.1
    Tom Scott

*   Respect cookie options in setting cookie with session ID
    Michael Dawson

*   Update tests and gemfiles to work on all supported versions.

    Do not depend on pre-release versions of gems.

    Move tests to use minitest-rails to alleviate some of the dependency hell.

    Remove version_test.rb because that's dumb.
    Connor Shea

v5.0.0
--------------------------------------------------------------------------------

*   Update README.md (#12)
    Nicolas

*   Bump to 5.0.0
    Ryan Bigg

*   Fix gem dependency versions
    Tom Scott

*   Pre-Release of v5.0.0
    Tom Scott

*   Disable rbx-19mode on Travis CI

    This syntax is no longer supported by Travis, so we aren't getting
    reliable builds and thus must disable its use, at least for now. We were
    getting problems on the Rails 4.0 and 4.1 Gemfiles.

    More information is available at
    https://travis-ci.org/redis-store/redis-actionpack/builds/112702496
    Tom Scott

*   exclue jruby-19 from rails5
    Marc Roberts

*   bump ruby 2.2 version in travis, rails5 need at least 2.2.4
    Marc Roberts

*   env is already an ActionDispatch::Request in rails5
    Marc Roberts

*   specify version of minitest-spec-rails
    Marc Roberts

*   need all of rails in gemfile for rails5
    Marc Roberts

*   use redis-store from github until a new gem is cut
    Marc Roberts

*   prevent rails5 deprecation warnings
    Marc Roberts

*   don't use mini_backtrace for now, incompatible with rails5
    Marc Roberts

*   bump rails5 gem version up to beta3
    Marc Roberts

*   use redis-rack via github for rails 5.0
    Marc Roberts

*   use minitest-spec-rails for consistency
    Marc Roberts

*   Merge remote-tracking branch 'upstream/master'
    Miles Matthias

*   update mini_specunit to minitest-spec-rails
    Marc Roberts

*   ignore .lock files in gemfiles
    Marc Roberts

*   correct gemfiles names in travis excludes
    Marc Roberts

*   fix gemspec path in gemfiles
    Marc Roberts

*   add multiple gemfiles for rails 4.0, 4.1, 4.2 and 5
    Marc Roberts

*   remove 1.9, add 2.1/2.2 rubies to travis
    Marc Roberts

*   Loosen dependancy on actionpack to support Rails 5
    Marc Roberts

*   travis ci add before_install
    shiro16

*   fixed travis.yml
    shiro16

*   travis ci add Ruby 2.1 and 2.2, 2.3.0
    shiro16

*   ignore stdout, file resulted from running tests
    Miles Matthias

*   Revert "Update README.md"

    This reverts commit a4c7f94ed6283b28a34079b5a4917897d6a2b77d.
    Ryan Bigg

*   Update README.md
    Ryan Bigg

*   These silly version tests
    Ryan Bigg

v4.0.1
--------------------------------------------------------------------------------
G
*   Bump to 4.0.1
    Ryan Bigg

*   support the same values for domain as rails' session stores usually do

     * needed to change the tests based on test in rails, so the options for the session store could be changed per test

     Fixes #2
    Michael Reinsch

v4.0.0
--------------------------------------------------------------------------------

*   Enable CI
    Luca Guidi

*   Move from jodosha/redis-store
    Luca Guidi
