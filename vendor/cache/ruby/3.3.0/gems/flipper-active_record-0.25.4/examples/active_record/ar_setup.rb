require 'bundler/setup'
require 'active_record'
ActiveRecord::Base.establish_connection({
  adapter: 'sqlite3',
  database: ':memory:',
})

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
