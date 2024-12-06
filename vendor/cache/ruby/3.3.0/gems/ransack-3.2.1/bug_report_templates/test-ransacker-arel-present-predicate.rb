# test-ransacker-arel-present-predicate.rb

# Run it in your console with: `ruby test-ransacker-arel-present-predicate.rb`

# If you change the gem dependencies, run it with:
# `rm gemfile* && ruby test-ransacker-arel-present-predicate.rb`

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
  create_table :projects, force: true do |t|
    t.string :name
    t.string :number
  end
end

class Project < ActiveRecord::Base
  ransacker :name do
    Arel.sql('projects.name')
  end

  ransacker :number do |parent|
    parent.table[:number]
  end
end

class BugTest < Minitest::Test
  def test_ransackers
    sql = Project.ransack({ number_present: 1 }).result.to_sql
    puts sql
    assert_equal "SELECT \"projects\".* FROM \"projects\" WHERE (\"projects\".\"number\" IS NOT NULL AND \"projects\".\"number\" != '')", sql

    sql = Project.ransack({ name_present: 1 }).result.to_sql
    puts sql
    assert_equal "SELECT \"projects\".* FROM \"projects\" WHERE (projects.name IS NOT NULL AND projects.name != '')", sql
  end
end
