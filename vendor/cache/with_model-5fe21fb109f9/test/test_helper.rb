# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Workaround for JRuby CI failure https://github.com/jruby/jruby/issues/6547#issuecomment-774104996
if RUBY_ENGINE == 'jruby'
  require 'i18n/backend'
  require 'i18n/backend/simple'
end

require 'with_model'
require 'minitest/autorun'

WithModel.runner = :minitest

module MiniTest
  class Test
    extend WithModel
  end
end

is_jruby = RUBY_PLATFORM == 'java'
adapter = is_jruby ? 'jdbcsqlite3' : 'sqlite3'

# WithModel requires ActiveRecord::Base.connection to be established.
# If ActiveRecord already has a connection, as in a Rails app, this is unnecessary.
require 'active_record'
ActiveRecord::Base.establish_connection(adapter: adapter, database: ':memory:')
