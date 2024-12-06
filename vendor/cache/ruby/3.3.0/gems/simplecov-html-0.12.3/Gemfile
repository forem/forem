# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake", ">= 11"

# Use local copy of simplecov in development if you want to
# gem "simplecov", :path => File.dirname(__FILE__) + "/../simplecov"
gem "simplecov", :github => "simplecov-ruby/simplecov"

group :test do
  gem "minitest"
end

group :development do
  gem "rubocop"
  # sprockets 4.0 requires ruby 2.5+
  gem "sprockets", "~> 3.7"
  gem "uglifier"
  gem "yui-compressor"
end
