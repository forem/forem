# rubocop:disable LineLength
source "https://rubygems.org"
ruby "2.5.1"

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
gem "administrate", "~> 0.9"
gem "ahoy_email", "~> 0.5"
gem "airbrake", "~> 5.8"
gem "algoliasearch-rails", "~> 1.20"
gem "algorithmia", "~> 1.0"
gem "ancestry", "~> 3.0"
gem "autoprefixer-rails", "~> 6.7"
gem "aws-sdk-lambda", "~> 1.5" # Just Lambda. For more, install aws-sdk gem
gem "bourbon", "~> 1.4"
gem "buffer", github: "bufferapp/buffer-ruby"
gem "carrierwave", "~> 1.2"
gem "carrierwave-bombshelter", "~> 0.2"
gem "cloudinary", "~> 1.9"
gem "counter_culture", "~> 1.9"
gem "csv_shaper", "~> 1.3"
gem "dalli", "~> 2.7"
gem "delayed_job_active_record", "~> 4.1"
gem "devise", "~> 4.4"
gem "draper", "~> 3.0"
gem "email_validator", "~> 1.6"
gem "envied", "~> 0.9"
gem "fastly", "~> 1.15"
gem "fastly-rails", "~> 0.8"
gem "feedjira", "~> 2.1"
gem "figaro", "~> 1.1"
gem "flipflop", "~> 2.3"
gem "fog", "~> 1.41"
gem "front_matter_parser", "~> 0.1"
gem "gibbon", "~> 2.2"
gem "google-api-client", "~> 0.19"
gem "html_truncator", "~> 0.4"
gem "httparty", "~> 0.16"
gem "inline_svg", "~> 0.12"
gem "jbuilder", "~> 2.7"
gem "jquery-rails", "~> 4.3"
gem "kaminari", "~> 1.1"
gem "keen", "~> 0.7"
gem "liquid", "~> 4.0"
gem "nokogiri", "~> 1.8"
gem "octokit", "~> 4.12"
gem "omniauth", "~> 1.8"
gem "omniauth-github", "~> 1.3"
gem "omniauth-twitter", "~> 1.4"
gem "pg", "~> 1.0"
gem "pry", "~> 0.11"
gem "pry-rails", "~> 0.3"
gem "puma", "~> 3.12"
gem "puma_worker_killer", "~> 0.1"
gem "pundit", "~> 2.0"
gem "pusher", "~> 1.3"
gem "rack-host-redirect", "~> 1.3"
gem "rack-timeout", "~> 0.5"
gem "rails", "~> 5.1"
gem "rails-assets-airbrake-js-client", "~> 1.4", source: "https://rails-assets.org"
gem "rails-observers", "~> 0.1"
gem "recaptcha", "~> 4.12", require: "recaptcha/rails"
gem "redcarpet", "~> 3.4"
gem "reverse_markdown", "~> 1.0"
gem "rolify", "~> 5.2"
gem "rouge", "~> 3.2"
gem "s3_direct_upload", "~> 0.1"
gem "sass-rails", "~> 5.0"
gem "sdoc", "~> 0.4", group: :doc
gem "serviceworker-rails", "~> 0.5"
gem "share_meow_client", "~> 0.1"
gem "skylight", "~> 2.0"
gem "slack-notifier", "~> 1.5"
gem "sprockets", "~> 3.7"
gem "sprockets-es6", "~> 0.9"
gem "staccato", "~> 0.5"
gem "storext", "~> 2.2"
gem "stream_rails", "~> 2.6"
gem "stripe", "~> 3.25"
gem "therubyracer", "~> 0.12", platforms: :ruby
gem "timber", "~> 2.6"
gem "twilio-ruby", "~> 5.10"
gem "twitter", "~> 6.2"
gem "uglifier", "~> 4.1"
gem "validate_url", "~> 1.0"
gem "webpacker", "~> 3.5"
gem "webpush", "~> 0.3"

group :development do
  gem "better_errors", "~> 2.5"
  gem "binding_of_caller", "~> 0.8"
  gem "brakeman", "~> 4.3", require: false
  gem "bullet", "~> 5.7"
  gem "bundler-audit", "~> 0.6"
  gem "derailed_benchmarks", "~> 1.3"
  gem "guard", "~> 2.14", require: false
  gem "guard-livereload", "~> 2.5", require: false
  gem "guard-rspec", "~> 4.7", require: false
  gem "rb-fsevent", "~> 0.10", require: false
  gem "web-console", "~> 3.5"
end

group :development, :test do
  gem "capybara", "~> 3.6"
  gem "derailed", "~> 0.1"
  gem "faker", git: "https://github.com/stympy/faker.git", branch: "master"
  gem "fix-db-schema-conflicts", github: "thepracticaldev/fix-db-schema-conflicts", branch: "master"
  gem "memory_profiler", "~> 0.9"
  gem "parallel_tests", "~> 2.22"
  gem "pry-byebug", "~> 3.6"
  gem "rspec-rails", "~> 3.8"
  gem "rspec-retry", "~> 0.6"
  gem "rubocop", "~> 0.57", require: false
  gem "rubocop-rspec", "~> 1.29"
  gem "spring", "~> 2.0"
  gem "spring-commands-rspec", "~> 1.0"
  gem "vcr", "~> 4.0"
end

group :test do
  gem "approvals", "~> 0.0"
  gem "chromedriver-helper", "~> 2.1"
  gem "database_cleaner", "~> 1.7"
  gem "factory_bot_rails", "~> 4.11"
  gem "fake_stripe", "~> 0.1"
  gem "launchy", "~> 2.4"
  gem "pundit-matchers", "~> 1.6"
  gem "rails-controller-testing", "~> 1.0"
  gem "ruby-prof", "~> 0.17", require: false
  gem "selenium-webdriver", "~> 3.12"
  gem "shoulda-matchers", "~> 3.1", require: false
  gem "simplecov", "~> 0.16", require: false
  gem "sinatra", "~> 2.0"
  gem "stackprof", "~> 0.2", require: false, platforms: :ruby
  gem "stripe-ruby-mock", "~> 2.5", require: "stripe_mock"
  gem "test-prof", "~> 0.5"
  gem "timecop", "~> 0.9"
  gem "webmock", "~> 3.4"
end
# rubocop:enable LineLength
