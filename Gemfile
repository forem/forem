# coding: utf-8

git_source(:github) { |name| "https://github.com/#{name}.git" }
source "https://rubygems.org"
ruby File.read(File.join(File.dirname(__FILE__), ".ruby-version")).strip

group :production do
  gem "hypershield", "~> 0.2.2" # Allow admins to query data via internal
  gem "nakayoshi_fork", "~> 0.0.4" # solves CoW friendly problem on MRI 2.2 and later
  gem "rack-host-redirect", "~> 1.3" # Lean and simple host redirection via Rack middleware
end

gem "active_record_union", "~> 1.3" # Adds proper union and union_all methods to ActiveRecord::Relation
gem "acts-as-taggable-on", "~> 9.0" # A tagging plugin for Rails applications that allows for custom tagging along dynamic contexts
gem "acts_as_follower", github: "forem/acts_as_follower", branch: "master" # Allow any model to follow any other model
gem "addressable", "~> 2.8" # A replacement for the URI implementation that is part of Ruby's standard library
gem "ahoy_email", "~> 2.1.3" # Email analytics for Rails
gem "ahoy_matey", "~> 4.1" # Tracking analytics for Rails
gem "ancestry", "~> 4.2" # Ancestry allows the records of a ActiveRecord model to be organized in a tree structure
gem "blazer", "~> 2.6" # Allows admins to query data
gem "bootsnap", ">= 1.1.0", require: false # Boot large ruby/rails apps faster
gem "carrierwave", "~> 2.2" # Upload files in your Ruby applications, map them to a range of ORMs, store them on different backends
gem "carrierwave-bombshelter", "~> 0.2" # Protect your carrierwave from image bombs
gem "cloudinary", "~> 1.23" # Client library for easily using the Cloudinary service
gem "counter_culture", "~> 3.2" # counter_culture provides turbo-charged counter caches that are kept up-to-date
gem "ddtrace", "~> 1.3.0" # ddtrace is Datadog’s tracing client for Ruby.
gem "devise", "~> 4.8" # Flexible authentication solution for Rails
gem "devise_invitable", "~> 2.0.6" # Allows invitations to be sent for joining
gem "dogstatsd-ruby", "~> 4.8" # A client for DogStatsD, an extension of the StatsD metric server for Datadog
gem "email_validator", "~> 2.2" # Email validator for Rails and ActiveModel
gem "emoji_regex", "~> 3.2" # A pair of Ruby regular expressions for matching Unicode Emoji symbols
gem "fastimage", "~> 2.2" # FastImage finds the size or type of an image given its uri by fetching as little as needed.
gem "fastly", "~> 3.0" # Client library for the Fastly acceleration system
gem "feedjira", "~> 3.2" # A feed fetching and parsing library
gem "field_test", "~> 0.5" # A/B testing
gem "flipper", "~> 0.25.0" # Feature flipping / flags for Ruby
gem "flipper-active_record", "~> 0.25.0" # Store Flipper flags in ActiveRecord
gem "flipper-active_support_cache_store", "~> 0.25.0" # Cache feature flags for a short time
gem "flipper-ui", "~> 0.25.0"
gem "fog-aws", "~> 3.14" # 'fog' gem to support Amazon Web Services
gem "front_matter_parser", "~> 1.0" # Parse a front matter from syntactically correct strings or files
gem "gemoji", "~> 4.0.0.rc3" # Character information and metadata for standard and custom emoji
gem "gibbon", "~> 3.4" # API wrapper for MailChimp's API
gem "hairtrigger", "~> 0.2.25" # HairTrigger lets you create and manage database triggers in a concise, db-agnostic, Rails-y way.
gem "honeybadger", "~> 4.12" # Used for tracking application errors
gem "honeycomb-beeline", "~> 2.11.0" # Monitoring and Observability gem
gem "html_truncator", "~> 0.4" # Truncate an HTML string properly
gem "httparty", "~> 0.20" # Makes http fun! Also, makes consuming restful web services dead easy
gem "httpclient", "~> 2.8.3" # Gives something like the functionality of libwww-perl (LWP) in Ruby
gem "i18n-js", "~> 3.9.2" # Helps with internationalization in Rails.
gem "imgproxy", "~> 2.1" # A gem that easily generates imgproxy URLs for your images
gem "inline_svg", "~> 1.8" # Embed SVG documents in your Rails views and style them with CSS
gem "jbuilder", "~> 2.11" # Create JSON structures via a Builder-style DSL
gem "js-routes", "~> 2.2" # Brings Rails named routes to javascript
gem "jsonapi-serializer", "~> 2.2" # Serializer for Ruby objects
gem "kaminari", "~> 1.2" # A Scope & Engine based, clean, powerful, customizable and sophisticated paginator
gem "katex", "~> 0.9.0" # This rubygem enables you to render TeX math to HTML using KaTeX. It uses ExecJS under the hood
gem "liquid", "~> 5.4" # A secure, non-evaling end user template engine with aesthetic markup
gem "metainspector", "~> 5.12" # To get and parse website metadata for Open Graph rich objects
gem "nokogiri", "~> 1.13" # HTML, XML, SAX, and Reader parser
gem "octokit", "~> 5.2" # Simple wrapper for the GitHub API
gem "oj", "~> 3.13" # JSON parser and object serializer
gem "omniauth", "~> 2.1" # A generalized Rack framework for multiple-provider authentication
gem "omniauth-apple", "~> 1.0" # OmniAuth strategy for Sign In with Apple
gem "omniauth-facebook", "~> 9.0" # OmniAuth strategy for Facebook
gem "omniauth-github", "~> 2.0" # OmniAuth strategy for GitHub
gem "omniauth-google-oauth2", "~> 1.0"
gem "omniauth-rails_csrf_protection", "~> 1.0" # Provides CSRF protection on OmniAuth request endpoint on Rails application.
gem "omniauth-twitter", "~> 1.4" # OmniAuth strategy for Twitter
gem "parallel", "~> 1.22" # Run any kind of code in parallel processes
gem "patron", "~> 0.13.3" # HTTP client library based on libcurl, used with GitHub OAuth client
gem "pg", "~> 1.4" # Pg is the Ruby interface to the PostgreSQL RDBMS
gem "pg_query", ">= 0.9.0" # Allows PGHero to analyze queries
gem "pg_search", "~> 2.3.6" # PgSearch builds Active Record named scopes that take advantage of PostgreSQL's full text search
gem "pghero", "~> 2.8" # Dashboard for Postgres
gem "puma", "~> 5.6.4" # Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server
gem "pundit", "~> 2.2" # Object oriented authorization for Rails applications
gem "rack-attack", "~> 6.6.1" # Used to throttle requests to prevent brute force attacks
gem "rack-cors", "~> 1.1" # Middleware that will make Rack-based apps CORS compatible
gem "rack-timeout", "~> 0.6" # Rack middleware which aborts requests that have been running for longer than a specified timeout
gem "rails", "~> 7.0.3.1" # Ruby on Rails
gem "ransack", "~> 3.2" # Searching and sorting
gem "recaptcha", "~> 5.10", require: "recaptcha/rails" # Helpers for the reCAPTCHA API
gem "redcarpet", "~> 3.5" # A fast, safe and extensible Markdown to (X)HTML parser

gem "redis", "~> 4.7.1" # Redis ruby client
gem "redis-actionpack", "~> 5.3.0" # Redis session store for ActionPack. Used for storing the Rails session in Redis.
gem "rpush", "~> 7.0" # Push Notification library for Rails
gem "rpush-redis", "~> 1.1" # Redis module capability for rpush library

gem "request_store", "~> 1.5" # RequestStore gives you per-request global storage
gem "reverse_markdown", "~> 2.1" # Map simple html back into markdown
gem "rolify", "~> 6.0" # Very simple Roles library
gem "rouge", "~> 3.30" # A pure-ruby code highlighter
gem "rss", "~> 0.2.9" # Ruby's standard library for RSS
gem "rubyzip", "~> 2.3" # Rubyzip is a ruby library for reading and writing zip files
gem "s3_direct_upload", "~> 0.1" # Direct Upload to Amazon S3
gem "sidekiq", "~> 6.5.3" # Sidekiq is used to process background jobs with the help of Redis
gem "sidekiq-cron", "~> 1.7" # Allows execution of scheduled cron jobs as specific times
gem "sidekiq-unique-jobs", "~> 7.1.27" # Ensures that Sidekiq jobs are unique when enqueued
gem "slack-notifier", "~> 2.4" # A slim ruby wrapper for posting to slack webhooks
gem "sprockets-rails", "~> 3.4" # Sprockets Rails integration
gem "staccato", "~> 0.5" # Ruby Google Analytics Measurement
gem "sterile", "~> 1.0" # Transliterate Unicode and Latin1 text to 7-bit ASCII for URLs
gem "stripe", "~> 5.55" # Ruby library for the Stripe API
gem "strong_migrations", "~> 1.2" # Catch unsafe migrations
gem "twitter", "~> 7.0" # A Ruby interface to the Twitter API
gem "uglifier", "~> 4.2" # Uglifier minifies JavaScript files
gem "validate_url", "~> 1.0" # Library for validating urls in Rails
gem "vault", "~> 0.17" # Used to store secrets
gem "wcag_color_contrast", "~> 0.1" # Detect contrast of colors to determine readability and a11y.
gem "webpacker", "~> 5.4.3" # Use webpack to manage app-like JavaScript modules in Rails

group :development do
  gem "better_errors", "~> 2.9" # Provides a better error page for Rails and other Rack apps

  gem "brakeman", "~> 5.2", require: false # Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis
  gem "bundler-audit", "~> 0.9" # bundler-audit provides patch-level verification for Bundled apps
  gem "derailed_benchmarks", "~> 2.1", require: false # A series of things you can use to benchmark a Rails or Ruby app
  gem "easy_translate", "~> 0.5.1" # Google translate tie-in to be used with i18n tasks
  gem "erb_lint", "~> 0.0.37", require: false # ERB Linter tool
  gem "guard", "~> 2.18", require: false # Guard is a command line tool to easily handle events on file system modifications
  gem "guard-rspec", "~> 4.7", require: false # Guard::Rspec includes a DSL for running tests on change
  gem "i18n-tasks", "~> 1.0.11" # Helpers to find and manage missing and unused translations
  gem "listen", "~> 3.7", require: false # Helps 'listen' to file system modifications events (also used by other gems like guard)
  gem "memory_profiler", "~> 1.0", require: false # Memory profiling routines for Ruby 2.3+
  gem "solargraph", "~> 0.45", require: false # For LSP support (such as symbol renaming, documentation lookup)
  gem "solargraph-rails", "~> 0.3.1", require: false # For LSP support with Rails
  gem "web-console", "~> 4.2" # Rails Console on the Browser
  gem "yard", "~> 0.9" # Documentation format
  gem "yard-activerecord", "~> 0.0"
  gem "yard-activesupport-concern", "~> 0.0"
end

group :development, :test do
  gem "amazing_print", "~> 1.4" # Great Ruby debugging companion: pretty print Ruby objects to visualize their structure
  gem "bullet", "~> 7.0" # help to kill N+1 queries and unused eager loading
  gem "capybara", "~> 3.37.1" # Capybara is an integration testing tool for rack based web applications
  gem "cypress-rails", "~> 0.5" # For end to end tests (E2E)
  gem "debug", ">= 1.0.0" # Provide a debug with step capabilities
  gem "dotenv-rails", "~> 2.8.1" # For loading ENV variables locally
  gem "faker", "~> 2.22" # A library for generating fake data such as names, addresses, and phone numbers
  gem "knapsack_pro", "~> 3.3.1" # Help parallelize Ruby spec builds
  gem "pry", "~> 0.14" # An IRB alternative and runtime developer console
  gem "pry-rails", "~> 0.3" # Use Pry as your rails console
  gem "rspec-rails", "~> 5.1" # rspec-rails is a testing framework for Rails 3+
  gem "rswag-specs", "~> 2.5.1" # RSwag - Swagger-based DSL for rspec & accompanying rake task for generating Swagger files
  gem "rubocop", "~> 1.33", require: false # Automatic Ruby code style checking tool
  gem "rubocop-performance", "~> 1.14", require: false # A collection of RuboCop cops to check for performance optimizations in Ruby code
  gem "rubocop-rails", "~> 2.15", require: false # Automatic Rails code style checking tool
  gem "rubocop-rspec", "~> 2.12", require: false # Code style checking for RSpec files
  gem "sassc-rails", "~> 2.1.2" # Integrate SassC-Ruby into Rails
end

group :test do
  gem "exifr", ">= 1.3.6" # EXIF Reader is a module to read EXIF from JPEG and TIFF images
  gem "factory_bot_rails", "~> 6.2" # factory_bot is a fixtures replacement with a straightforward definition syntax, support for multiple build strategies
  gem "fakeredis", "~> 0.8.0" # Fake (In-memory) driver for redis-rb. Useful for testing environment and machines without Redis.
  gem "launchy", "~> 2.5" # Launchy is helper class for launching cross-platform applications in a fire and forget manner.
  gem "pundit-matchers", "~> 1.7" # A set of RSpec matchers for testing Pundit authorisation policies
  gem "rspec-retry", "~> 0.6" # retry intermittently failing rspec examples
  gem "ruby-prof", "~> 1.4", require: false # ruby-prof is a fast code profiler for Ruby
  gem "shoulda-matchers", "~> 5.1.0", require: false # Simple one-liner tests for common Rails functionality
  gem "simplecov", "~> 0.21.2", require: false # Code coverage with a powerful configuration library and automatic merging of coverage across test suites
  gem "stackprof", "~> 0.2", require: false, platforms: :ruby # stackprof is a fast sampling profiler for ruby code, with cpu, wallclock and object allocation samplers
  gem "stripe-ruby-mock", "3.1.0.rc3", require: "stripe_mock" # A drop-in library to test stripe without hitting their servers
  gem "test-prof", "~> 1.0" # Ruby Tests Profiling Toolbox
  gem "timecop", "~> 0.9" # A gem providing "time travel" and "time freezing" capabilities, making it dead simple to test time-dependent code
  gem "vcr", "~> 6.1" # Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests
  gem "webdrivers", "~> 5.0" # Run Selenium tests more easily with install and updates for all supported webdrivers
  gem "webmock", "~> 3.17", require: false # WebMock allows stubbing HTTP requests and setting expectations on HTTP requests
  gem "with_model", "~> 2.1.6" # Dynamically build a model within an RSpec context
  gem "zonebie", "~> 0.6.1" # Runs your tests in a random timezone
end
