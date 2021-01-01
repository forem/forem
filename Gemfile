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
gem "acts-as-taggable-on", "~> 6.5" # A tagging plugin for Rails applications that allows for custom tagging along dynamic contexts
gem "acts_as_follower", github: "forem/acts_as_follower", branch: "master" # Allow any model to follow any other model
gem "addressable", "~> 2.7" # A replacement for the URI implementation that is part of Ruby's standard library
gem "ahoy_email", "~> 1.1" # Email analytics for Rails
gem "ahoy_matey", "~> 3.1" # Tracking analytics for Rails
gem "ancestry", "~> 3.2" # Ancestry allows the records of a ActiveRecord model to be organized in a tree structure
gem "blazer", "~> 2.4.0" # Allows admins to query data
gem "bootsnap", ">= 1.1.0", require: false # Boot large ruby/rails apps faster
gem "buffer", "~> 0.1" # Buffer is a Ruby Wrapper for the Buffer API
gem "carrierwave", "~> 2.0" # Upload files in your Ruby applications, map them to a range of ORMs, store them on different backends
gem "carrierwave-bombshelter", "~> 0.2" # Protect your carrierwave from image bombs
gem "cld", "~> 0.8" # Compact Language Detection for Ruby
gem "cloudinary", "~> 1.18" # Client library for easily using the Cloudinary service
gem "counter_culture", "~> 2.7" # counter_culture provides turbo-charged counter caches that are kept up-to-date
gem "ddtrace", "~> 0.43.0" # ddtrace is Datadog’s tracing client for Ruby.
gem "devise", "~> 4.7" # Flexible authentication solution for Rails
gem "devise_invitable", "~> 2.0.3" # Allows invitations to be sent for joining
gem "dogstatsd-ruby", "~> 4.8" # A client for DogStatsD, an extension of the StatsD metric server for Datadog
gem "doorkeeper", "~> 5.4" # Oauth 2 provider
gem "elasticsearch", "~> 7.10" # Powers DEVs core search functionality
gem "email_validator", "~> 2.2" # Email validator for Rails and ActiveModel
gem "emoji_regex", "~> 3.2" # A pair of Ruby regular expressions for matching Unicode Emoji symbols
gem "fastly", "~> 2.5" # Client library for the Fastly acceleration system
gem "feedjira", "~> 3.1" # A feed fetching and parsing library
gem "field_test", "~> 0.4" # A/B testing
gem "flipper", "~> 0.20.0" # Feature flipping / flags for Ruby
gem "flipper-active_record", "~> 0.20.0" # Store Flipper flags in ActiveRecord
gem "flipper-ui", "~> 0.20.0"
gem "fog-aws", "~> 3.7" # 'fog' gem to support Amazon Web Services
gem "front_matter_parser", "~> 0.2" # Parse a front matter from syntactically correct strings or files
gem "gemoji", "~> 4.0.0.rc2" # Character information and metadata for standard and custom emoji
gem "gibbon", "~> 3.3" # API wrapper for MailChimp's API
gem "honeybadger", "~> 4.7" # Used for tracking application errors
gem "honeycomb-beeline", "~> 2.3.0" # Monitoring and Observability gem
gem "html_truncator", "~> 0.4" # Truncate an HTML string properly
gem "htmlentities", "~> 4.3", ">= 4.3.4" # A module for encoding and decoding (X)HTML entities
gem "httparty", "~> 0.18" # Makes http fun! Also, makes consuming restful web services dead easy
gem "imgproxy", "~> 1.2" # A gem that easily generates imgproxy URLs for your images
gem "inline_svg", "~> 1.7" # Embed SVG documents in your Rails views and style them with CSS
gem "jbuilder", "~> 2.10" # Create JSON structures via a Builder-style DSL
gem "jquery-rails", "~> 4.4" #  A gem to automate using jQuery with Rails
gem "jsonapi-serializer", "~> 2.1" # Serializer for Ruby objects
gem "kaminari", "~> 1.2" # A Scope & Engine based, clean, powerful, customizable and sophisticated paginator
gem "katex", "~> 0.6.0" # This rubygem enables you to render TeX math to HTML using KaTeX. It uses ExecJS under the hood
gem "liquid", "~> 4.0" # A secure, non-evaling end user template engine with aesthetic markup
gem "mini_racer", "~> 0.3.1" # Minimal embedded v8
gem "nokogiri", "~> 1.10" # HTML, XML, SAX, and Reader parser
gem "octokit", "~> 4.20" # Simple wrapper for the GitHub API
gem "oj", "~> 3.10" # JSON parser and object serializer
gem "omniauth", "~> 1.9" # A generalized Rack framework for multiple-provider authentication
gem "omniauth-apple", "~> 1.0" # OmniAuth strategy for Sign In with Apple
gem "omniauth-facebook", "~> 8.0" # OmniAuth strategy for Facebook
gem "omniauth-github", "~> 1.3" # OmniAuth strategy for GitHub
gem "omniauth-twitter", "~> 1.4" # OmniAuth strategy for Twitter
gem "parallel", "~> 1.20" # Run any kind of code in parallel processes
gem "patron", "~> 0.13.3" # HTTP client library based on libcurl, used with Elasticsearch to support http keep-alive connections
gem "pg", "~> 1.2" # Pg is the Ruby interface to the PostgreSQL RDBMS
gem "puma", "~> 5.1.1" # Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server
gem "pundit", "~> 2.1" # Object oriented authorization for Rails applications
gem "pusher", "~> 1.4" # Ruby library for Pusher Channels HTTP API
gem "pusher-push-notifications", "~> 1.3" # Pusher Push Notifications Ruby server SDK
gem "rack-attack", "~> 6.3.1" # Used to throttle requests to prevent brute force attacks
gem "rack-cors", "~> 1.1" # Middleware that will make Rack-based apps CORS compatible
gem "rack-timeout", "~> 0.6" # Rack middleware which aborts requests that have been running for longer than a specified timeout
gem "rails", "~> 6.0.3" # Ruby on Rails
gem "rails-settings-cached", ">= 2.1.1" # Settings plugin for Rails that makes managing a table of global key, value pairs easy.
gem "ransack", "~> 2.4" # Searching and sorting
gem "recaptcha", "~> 5.6", require: "recaptcha/rails" # Helpers for the reCAPTCHA API
gem "redcarpet", "~> 3.5" # A fast, safe and extensible Markdown to (X)HTML parser
gem "redis", "~> 4.2.5" # Redis ruby client

# NOTE: [@rhymes]: sign in doesn't work with the redis-rack 2.1.0+ or with redis-actionpack 5.2.0+
# We need to investigate why exactly, in the meantime we are hardcoding these two transitive dependencies
# (added by redis-rails) to keep them at the latest working version
gem "redis-actionpack", "5.1.0" # Redis session store for ActionPack. Used for storing the Rails session in Redis.
gem "redis-rack", "2.0.6" # Redis Store for Rack applications

gem "redis-rails", "~> 5.0.2" # Redis for Ruby on Rails
gem "request_store", "~> 1.5" # RequestStore gives you per-request global storage
gem "reverse_markdown", "~> 2.0" # Map simple html back into markdown
gem "rolify", "~> 5.3" # Very simple Roles library
gem "rouge", "~> 3.26" # A pure-ruby code highlighter
gem "rubyzip", "~> 2.3" # Rubyzip is a ruby library for reading and writing zip files
gem "s3_direct_upload", "~> 0.1" # Direct Upload to Amazon S3
gem "sassc-rails", "~> 2.1.2" # Integrate SassC-Ruby into Rails
gem "sidekiq", "~> 6.1.2" # Sidekiq is used to process background jobs with the help of Redis
gem "sidekiq-cron", "~> 1.1" # Allows execution of scheduled cron jobs as specific times
gem "sidekiq-unique-jobs", "~> 6.0.25" # Ensures that Sidekiq jobs are unique when enqueued
gem "sitemap_generator", "~> 6.1" # SitemapGenerator is a framework-agnostic XML Sitemap generator
gem "slack-notifier", "~> 2.3" # A slim ruby wrapper for posting to slack webhooks
gem "sprockets", "~> 4.0" # Sprockets is a Rack-based asset packaging system
gem "staccato", "~> 0.5" # Ruby Google Analytics Measurement
gem "store_attribute", "~> 0.8.1" # ActiveRecord extension which adds typecasting to store accessors.
gem "storext", "~> 3.1" # Add type-casting and other features on top of ActiveRecord::Store.store_accessor
gem "stripe", "~> 5.28" # Ruby library for the Stripe API
gem "strong_migrations", "~> 0.7" # Catch unsafe migrations
gem "twilio-ruby", "~> 5.45" # The official library for communicating with the Twilio REST API
gem "twitter", "~> 7.0" # A Ruby interface to the Twitter API
gem "uglifier", "~> 4.2" # Uglifier minifies JavaScript files
gem "ulid", "~> 1.2" # Universally Unique Lexicographically Sortable Identifier implementation for Ruby
gem "validate_url", "~> 1.0" # Library for validating urls in Rails
gem "vault", "~> 0.15" # Used to store secrets
gem "wcag_color_contrast", "~> 0.1" # Detect contrast of colors to determine readability and a11y.
gem "webpacker", "~> 5.2.1" # Use webpack to manage app-like JavaScript modules in Rails

group :development do
  gem "better_errors", "~> 2.9" # Provides a better error page for Rails and other Rack apps
  gem "binding_of_caller", "~> 1.0" # Retrieve the binding of a method's caller
  gem "brakeman", "~> 4.10", require: false # Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis
  gem "bundler-audit", "~> 0.7" # bundler-audit provides patch-level verification for Bundled apps
  gem "derailed_benchmarks", "~> 1.8", require: false # A series of things you can use to benchmark a Rails or Ruby app
  gem "erb_lint", github: "thepracticaldev/erb-lint", branch: "jess/remove-version-pinning", require: false # ERB Linter tool
  gem "fix-db-schema-conflicts", "~> 3.0" # Ensures consistent output of db/schema.rb despite local differences in the database
  gem "guard", "~> 2.16", require: false # Guard is a command line tool to easily handle events on file system modifications
  gem "guard-livereload", "~> 2.5", require: false # Guard::LiveReload automatically reloads your browser when 'view' files are modified
  gem "guard-rspec", "~> 4.7", require: false # Guard::RSpec automatically run your specs
  gem "listen", "~> 3.4", require: false # Helps 'listen' to file system modifications events (also used by other gems like guard)
  gem "memory_profiler", "~> 0.9", require: false # Memory profiling routines for Ruby 2.3+
  gem "pry", "~> 0.13" # An IRB alternative and runtime developer console
  gem "pry-rails", "~> 0.3" # Use Pry as your rails console
  gem "web-console", "~> 4.1" # Rails Console on the Browser
  gem "yard", "~> 0.9.26" # YARD is a documentation generation tool for the Ruby programming language
  gem "yard-activerecord", "~> 0.0.16" # YARD extension that handles and interprets methods used when developing applications with ActiveRecord
  gem "yard-activesupport-concern", "~> 0.0.1" # YARD extension that brings support for modules making use of ActiveSupport::Concern
end

group :development, :test do
  gem "amazing_print", "~> 1.2" # Great Ruby debugging companion: pretty print Ruby objects to visualize their structure
  gem "bullet", "~> 6.1" # help to kill N+1 queries and unused eager loading
  gem "capybara", "~> 3.34" # Capybara is an integration testing tool for rack based web applications
  gem "dotenv-rails", "~> 2.7.6" # For loading ENV variables locally
  gem "faker", "~> 2.15" # A library for generating fake data such as names, addresses, and phone numbers
  gem "knapsack_pro", "~> 2.10.1" # Help parallelize Ruby spec builds
  gem "pry-byebug", "~> 3.8" # Combine 'pry' with 'byebug'. Adds 'step', 'next', 'finish', 'continue' and 'break' commands to control execution
  gem "rspec-rails", "~> 4.0" # rspec-rails is a testing framework for Rails 3+
  gem "rubocop", "~> 1.7", require: false # Automatic Ruby code style checking tool
  gem "rubocop-performance", "~> 1.9", require: false # A collection of RuboCop cops to check for performance optimizations in Ruby code
  gem "rubocop-rails", "~> 2.9", require: false # Automatic Rails code style checking tool
  gem "rubocop-rspec", "~> 2.1", require: false # Code style checking for RSpec files
  gem "spring", "~> 2.1" # Preloads your application so things like console, rake and tests run faster
  gem "spring-commands-rspec", "~> 1.0" # rspec command for spring
end

group :test do
  gem "approvals", "~> 0.0" # A library to make it easier to do golden-master style testing in Ruby
  gem "database_cleaner-active_record", "~> 1.8.0", require: false # Strategies for cleaning databases using ActiveRecord. Can be used to ensure a clean state for testing.
  gem "exifr", ">= 1.3.6" # EXIF Reader is a module to read EXIF from JPEG and TIFF images
  gem "factory_bot_rails", "~> 6.1" # factory_bot is a fixtures replacement with a straightforward definition syntax, support for multiple build strategies
  gem "launchy", "~> 2.5" # Launchy is helper class for launching cross-platform applications in a fire and forget manner.
  gem "pundit-matchers", "~> 1.6" # A set of RSpec matchers for testing Pundit authorisation policies
  gem "rspec-retry", "~> 0.6" # retry intermittently failing rspec examples
  gem "ruby-prof", "~> 1.4", require: false # ruby-prof is a fast code profiler for Ruby
  gem "shoulda-matchers", "~> 4.4.1", require: false # Simple one-liner tests for common Rails functionality
  gem "simplecov", "~> 0.20.0", require: false # Code coverage with a powerful configuration library and automatic merging of coverage across test suites
  gem "stackprof", "~> 0.2", require: false, platforms: :ruby # stackprof is a fast sampling profiler for ruby code, with cpu, wallclock and object allocation samplers
  gem "stripe-ruby-mock", "~> 3.0", require: "stripe_mock" # A drop-in library to test stripe without hitting their servers
  gem "test-prof", "~> 0.12" # Ruby Tests Profiling Toolbox
  gem "timecop", "~> 0.9" # A gem providing "time travel" and "time freezing" capabilities, making it dead simple to test time-dependent code
  gem "vcr", "~> 6.0" # Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests
  gem "webdrivers", "~> 4.4" # Run Selenium tests more easily with install and updates for all supported webdrivers
  gem "webmock", "~> 3.11", require: false # WebMock allows stubbing HTTP requests and setting expectations on HTTP requests
  gem "zonebie", "~> 0.6.1" # Runs your tests in a random timezone
end
