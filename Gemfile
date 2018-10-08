# rubocop:disable LineLength
source "https://rubygems.org"
ruby "2.6.0"

# Enforce git to transmitted via https.
# workaround until bundler 2.0 is released.
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

group :production do
  gem "nakayoshi_fork"
end

gem "actionpack-action_caching", "~> 1.2"
gem "active_record_union", "~> 1.3"
gem "acts-as-taggable-on", "~> 5.0"
gem "acts_as_follower", github: "thepracticaldev/acts_as_follower", branch: "master"
gem "addressable", "~> 2.5", ">= 2.5.2"
gem "administrate", "~> 0.11"
gem "ahoy_email", "~> 0.5"
gem "airbrake", "~> 7.4"
gem "algoliasearch-rails", "~> 1.20"
gem "algorithmia", "~> 1.0"
gem "ancestry", "~> 3.0"
gem "autoprefixer-rails", "~> 9.4"
gem "aws-sdk-lambda", "~> 1.16" # Just Lambda. For more, install aws-sdk gem
gem "bourbon", "~> 5.1"
gem "buffer", "~> 0.1"
gem "carrierwave", "~> 1.3"
gem "carrierwave-bombshelter", "~> 0.2"
gem "cloudinary", "~> 1.9"
gem "counter_culture", "~> 2.1"
gem "csv_shaper", "~> 1.3"
gem "dalli", "~> 2.7"
gem "delayed_job_active_record", "~> 4.1"
gem "devise", "~> 4.5"
gem "draper", "~> 3.0"
gem "email_validator", "~> 1.6"
gem "emoji_regex", "~> 1.0"
gem "envied", "~> 0.9"
gem "fastly", "~> 1.15"
gem "fastly-rails", "~> 0.8"
gem "feedjira", "~> 2.2"
gem "figaro", "~> 1.1"
gem "fog", "~> 1.41"
gem "front_matter_parser", "~> 0.2"
gem "gemoji", "~> 3.0.0"
gem "gibbon", "~> 2.2"
gem "google-api-client", "~> 0.27"
gem "honeycomb-rails"
gem "html_truncator", "~> 0.4"
gem "httparty", "~> 0.16"
gem "inline_svg", "~> 1.3"
gem "jbuilder", "~> 2.8"
gem "jquery-rails", "~> 4.3"
gem "kaminari", "~> 1.1"
gem "libhoney", "~> 1.10"
gem "liquid", "~> 4.0"
gem "nokogiri", "~> 1.10"
gem "octokit", "~> 4.13"
gem "omniauth", "~> 1.9"
gem "omniauth-github", "~> 1.3"
gem "omniauth-twitter", "~> 1.4"
gem "pg", "~> 1.1"
gem "pry", "~> 0.12"
gem "pry-rails", "~> 0.3"
gem "puma", "~> 3.12"
gem "pundit", "~> 2.0"
gem "pusher", "~> 1.3"
gem "pusher-push-notifications", "~> 1.0"
gem "rack-host-redirect", "~> 1.3"
gem "rack-timeout", "~> 0.5"
gem "rails", "~> 5.1"
gem "rails-assets-airbrake-js-client", "~> 1.5", source: "https://rails-assets.org"
gem "rails-observers", "~> 0.1"
gem "recaptcha", "~> 4.13", require: "recaptcha/rails"
gem "redcarpet", "~> 3.4"
gem "reverse_markdown", "~> 1.1"
gem "rolify", "~> 5.2"
gem "rouge", "~> 3.3"
gem "rubyzip", "~> 1.2", ">= 1.2.2"
gem "s3_direct_upload", "~> 0.1"
gem "sail", "~> 1.5"
gem "sass-rails", "~> 5.0"
gem "sdoc", "~> 1.0", group: :doc
gem "serviceworker-rails", "~> 0.5"
gem "share_meow_client", "~> 0.1"
gem "sitemap_generator", "~> 6.0"
gem "skylight", "~> 2.0"
gem "slack-notifier", "~> 2.3"
gem "sprockets", "~> 3.7"
gem "staccato", "~> 0.5"
gem "storext", "~> 2.2"
gem "stripe", "~> 3.25"
gem "timber", "~> 2.6"
gem "twilio-ruby", "~> 5.15"
gem "twitter", "~> 6.2"
gem "uglifier", "~> 4.1"
gem "validate_url", "~> 1.0"
gem "webpacker", "~> 3.5"
gem "webpush", "~> 0.3"

group :development do
  gem "better_errors", "~> 2.5"
  gem "binding_of_caller", "~> 0.8"
  gem "brakeman", "~> 4.3", require: false
  gem "bullet", "~> 5.9"
  gem "bundler-audit", "~> 0.6"
  gem "derailed_benchmarks", "~> 1.3"
  gem "guard", "~> 2.15", require: false
  gem "guard-livereload", "~> 2.5", require: false
  gem "guard-rspec", "~> 4.7", require: false
  gem "rb-fsevent", "~> 0.10", require: false
  gem "web-console", "~> 3.5"
end

group :development, :test do
  gem "capybara", "~> 3.12"
  gem "derailed", "~> 0.1"
  gem "faker", git: "https://github.com/stympy/faker.git", branch: "master"
  gem "fix-db-schema-conflicts", github: "thepracticaldev/fix-db-schema-conflicts", branch: "master"
  gem "memory_profiler", "~> 0.9"
  gem "parallel_tests", "~> 2.27"
  gem "pry-byebug", "~> 3.6"
  gem "rspec-rails", "~> 3.8"
  gem "rspec-retry", "~> 0.6"
  gem "rubocop", "~> 0.63", require: false
  gem "rubocop-rspec", "~> 1.31"
  gem "spring", "~> 2.0"
  gem "spring-commands-rspec", "~> 1.0"
  gem "vcr", "~> 4.0"
end

group :test do
  gem "approvals", "~> 0.0"
  gem "chromedriver-helper", "~> 2.1"
  gem "database_cleaner", "~> 1.7"
  gem "factory_bot_rails", "~> 4.11"
  gem "fake_stripe", "~> 0.2"
  gem "launchy", "~> 2.4"
  gem "pundit-matchers", "~> 1.6"
  gem "rails-controller-testing", "~> 1.0"
  gem "ruby-prof", "~> 0.17", require: false
  gem "selenium-webdriver", "~> 3.141"
  gem "shoulda-matchers", "~> 3.1", require: false
  gem "simplecov", "~> 0.16", require: false
  gem "sinatra", "~> 2.0"
  gem "stackprof", "~> 0.2", require: false, platforms: :ruby
  gem "stripe-ruby-mock", "~> 2.5", require: "stripe_mock"
  gem "test-prof", "~> 0.7"
  gem "timecop", "~> 0.9"
  gem "webmock", "~> 3.5"
  gem "zonebie", "~> 0.6.1"
end
# rubocop:enable LineLength
