source "https://rubygems.org"

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

# Until 1.13.2 is released due to Rubygems usage
gem 'ffi', '~> 1.12.0'

custom_gemfile = File.expand_path('Gemfile-custom', __dir__)
eval_gemfile custom_gemfile if File.exist?(custom_gemfile)

eval_gemfile 'Gemfile-sqlite-dependencies'
eval_gemfile 'Gemfile-rails-dependencies'
