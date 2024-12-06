# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  gem "mocha", "~> 0.13.2"
  gem "rack", ">= 2.0.6"
  gem "rake"

  # Update to 2.0.0 once it ships.
  gem "shoulda-context", "2.0.0.rc4"

  gem "test-unit"

  # Version doesn't matter that much, but this one contains some fixes for Ruby
  # 2.7 warnings that add noise to the test suite.
  gem "webmock", ">= 3.8.0"

  # Rubocop changes pretty quickly: new cops get added and old cops change
  # names or go into new namespaces. This is a library and we don't have
  # `Gemfile.lock` checked in, so to prevent good builds from suddenly going
  # bad, pin to a specific version number here. Try to keep this relatively
  # up-to-date, but it's not the end of the world if it's not.
  gem "rubocop", "0.80"

  platforms :mri do
    gem "byebug"
    gem "pry"
    gem "pry-byebug"
  end
end
