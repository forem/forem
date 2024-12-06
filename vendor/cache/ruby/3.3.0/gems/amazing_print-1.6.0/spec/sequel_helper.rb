# frozen_string_literal: true

if ExtVerifier.has_sequel?
  # Establish connection to in-memory SQLite DB
  DB = RUBY_PLATFORM == 'java' ? Sequel.connect('jdbc:sqlite::memory:') : Sequel.sqlite

  # Create the users table
  DB.create_table :sequel_users do
    primary_key :id
    String :first_name
    String :last_name
    TrueClass :admin
    DateTime :created_at
  end

  # Create models
  class SequelUser < Sequel::Model; end
end
