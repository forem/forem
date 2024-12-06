# test-ransack-scope-and-column-same-name.rb

# This is a stand-alone test case.

# Run it in your console with: `ruby test-ransack-scope-and-column-same-name.rb`

# If you change the gem dependencies, run it with:
# `rm gemfile* && ruby test-ransack-scope-and-column-same-name.rb`

unless File.exist?('Gemfile')
  File.write('Gemfile', <<-GEMFILE)
    source 'https://rubygems.org'

    # Rails master
    gem 'rails', github: 'rails/rails', branch: '6-1-stable'

    # Rails last release
    # gem 'rails'

    gem 'sqlite3'
    gem 'ransack', github: 'activerecord-hackery/ransack'
  GEMFILE

  system 'bundle install'
end

require 'bundler'
Bundler.setup(:default)

require 'active_record'
require 'minitest/autorun'
require 'logger'
require 'ransack'

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Display versions.
message = "Running test case with Ruby #{RUBY_VERSION}, Active Record #{
  ::ActiveRecord::VERSION::STRING}, Arel #{Arel::VERSION} and #{
  ::ActiveRecord::Base.connection.adapter_name}"
line = '=' * message.length
puts line, message, line

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.boolean :active, null: false, default: true
  end
end

class User < ActiveRecord::Base
  scope :activated, -> (boolean = true) { where(active: boolean) }

  private

  def self.ransackable_scopes(auth_object = nil)
    %i(activated)
  end
end

class BugTest < Minitest::Test
  def test_activated_scope_equals_true
    sql = User.ransack({ activated: true }).result.to_sql
    puts sql
    assert_equal(
      "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"active\" = 1", sql
      )
  end

  def test_activated_scope_equals_false
    sql = User.ransack({ activated: false }).result.to_sql
    puts sql
    assert_equal(
      "SELECT \"users\".* FROM \"users\"", sql
      )
  end
end
