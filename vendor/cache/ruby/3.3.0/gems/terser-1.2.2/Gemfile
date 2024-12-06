# frozen_string_literal: true

source "https://rubygems.org"

gemspec

unless RUBY_VERSION < '2.7'
  group :development do
    gem 'rubocop', '~> 1.60.1'
    gem 'rubocop-performance', '~> 1.20.2', :require => false
  end
end
