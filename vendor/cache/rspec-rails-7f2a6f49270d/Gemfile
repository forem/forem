source "https://rubygems.org"
version_file = File.expand_path('.rails-version', __dir__)
RAILS_VERSION = ENV['RAILS_VERSION'] || (File.exist?(version_file) && File.read(version_file).chomp) || ""

gemspec

eval_gemfile 'Gemfile-rspec-dependencies'

gem 'yard', '~> 0.9.24', require: false

group :documentation do
  gem 'github-markup', '~> 3.0.3'
  gem 'redcarpet', '~> 3.4.0', platforms: [:ruby]
  gem 'relish', '~> 0.7.1'
end

gem 'rake', '> 12'

if RUBY_VERSION.to_f >= 2.3
  gem 'rubocop', '~> 0.80.1'
end

gem 'capybara'

MAJOR =
  case RAILS_VERSION
  when /5-2-stable/
    5
  when /master/, /stable/, nil, false, ''
    6
  else
    /(\d+)[\.|-]\d+/.match(RAILS_VERSION).captures.first.to_i
  end

if MAJOR >= 6
  # sqlite3 is an optional, unspecified, dependency and Rails 6.0 only supports `~> 1.4`
  gem 'sqlite3', '~> 1.4', platforms: [:ruby]
else
  # Similarly, Rails 5.0 only supports '~> 1.3.6'. Rails 5.1-5.2 support '~> 1.3', '>= 1.3.6'
  gem 'sqlite3', '~> 1.3.6', platforms: [:ruby]
end

# Until 1.13.2 is released due to Rubygems usage
gem 'ffi', '~> 1.12.0'

custom_gemfile = File.expand_path('Gemfile-custom', __dir__)
eval_gemfile custom_gemfile if File.exist?(custom_gemfile)

eval_gemfile 'Gemfile-rails-dependencies'
