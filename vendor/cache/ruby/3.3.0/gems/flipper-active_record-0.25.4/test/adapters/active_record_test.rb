require 'test_helper'
require 'flipper/adapters/active_record'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

class ActiveRecordTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
                                          database: ':memory:')

  def setup
    @adapter = Flipper::Adapters::ActiveRecord.new

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE flipper_features (
        id integer PRIMARY KEY,
        key text NOT NULL UNIQUE,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE flipper_gates (
        id integer PRIMARY KEY,
        feature_key text NOT NULL,
        key text NOT NULL,
        value text DEFAULT NULL,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE UNIQUE INDEX index_gates_on_keys_and_value on flipper_gates (feature_key, key, value)
    SQL
  end

  def teardown
    ActiveRecord::Base.connection.execute("DROP table IF EXISTS `flipper_features`")
    ActiveRecord::Base.connection.execute("DROP table IF EXISTS `flipper_gates`")
  end

  def test_models_honor_table_name_prefixes_and_suffixes
    ActiveRecord::Base.table_name_prefix = :foo_
    ActiveRecord::Base.table_name_suffix = :_bar

    Flipper::Adapters::ActiveRecord.send(:remove_const, :Feature)
    Flipper::Adapters::ActiveRecord.send(:remove_const, :Gate)
    load("flipper/adapters/active_record.rb")

    assert_equal "foo_flipper_features_bar", Flipper::Adapters::ActiveRecord::Feature.table_name
    assert_equal "foo_flipper_gates_bar", Flipper::Adapters::ActiveRecord::Gate.table_name

  ensure
    ActiveRecord::Base.table_name_prefix = ""
    ActiveRecord::Base.table_name_suffix = ""

    Flipper::Adapters::ActiveRecord.send(:remove_const, :Feature)
    Flipper::Adapters::ActiveRecord.send(:remove_const, :Gate)
    load("flipper/adapters/active_record.rb")
  end
end
