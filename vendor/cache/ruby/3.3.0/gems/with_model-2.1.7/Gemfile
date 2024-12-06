# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

ar_branch = ENV.fetch('ACTIVE_RECORD_BRANCH', nil)
ar_version = ENV.fetch('ACTIVE_RECORD_VERSION', nil)
is_jruby = RUBY_PLATFORM == 'java'

if ar_branch
  gem 'activerecord', git: 'https://github.com/rails/rails.git', branch: ar_branch
  if ar_branch == 'master'
    gem 'arel', git: 'https://github.com/rails/arel.git'
    gem 'activerecord-jdbcsqlite3-adapter', git: 'https://github.com/jruby/activerecord-jdbc-adapter.git' if is_jruby
  end
elsif ar_version
  gem 'activerecord', ar_version
  if is_jruby && !Gem::Requirement.new(ar_version).satisfied_by?(Gem::Version.new('5.2.0'))
    gem 'activerecord-jdbcsqlite3-adapter', git: 'https://github.com/jruby/activerecord-jdbc-adapter.git'
  end
end

gem 'bundler'
gem 'minitest'
gem 'rake'
gem 'rspec'
gem 'rubocop'
gem 'rubocop-minitest'
gem 'rubocop-rake'
gem 'rubocop-rspec'
gem 'simplecov'
gem 'sqlite3', '~> 1.6.0' unless is_jruby
