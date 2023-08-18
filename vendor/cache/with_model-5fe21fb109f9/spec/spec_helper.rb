# frozen_string_literal: true

# Workaround for JRuby CI failure https://github.com/jruby/jruby/issues/6547#issuecomment-774104996
if RUBY_ENGINE == 'jruby'
  require 'i18n/backend'
  require 'i18n/backend/simple'
end

require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'with_model'

RSpec.configure do |config|
  config.extend WithModel

  config.warnings = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |c|
    c.syntax = :expect
  end
end

is_jruby = RUBY_PLATFORM == 'java'
adapter = is_jruby ? 'jdbcsqlite3' : 'sqlite3'

# WithModel requires ActiveRecord::Base.connection to be established.
# If ActiveRecord already has a connection, as in a Rails app, this is unnecessary.
require 'active_record'
ActiveRecord::Base.establish_connection(adapter: adapter, database: ':memory:')

I18n.enforce_available_locales = true if defined?(I18n) && I18n.respond_to?(:enforce_available_locales=)

if ENV['LOGGER']
  require 'logger'
  ActiveRecord::Base.logger = Logger.new($stdout)
end

module SpecHelper
  module RailsTestCompatibility
    require 'minitest'
    include Minitest::Assertions

    def assertions
      @assertions ||= 0
    end

    def assertions=(value)
      @assertions = value
    end
  end
end
