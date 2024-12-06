# dependencies
require "active_support"

# adapters
require_relative "strong_migrations/adapters/abstract_adapter"
require_relative "strong_migrations/adapters/mysql_adapter"
require_relative "strong_migrations/adapters/mariadb_adapter"
require_relative "strong_migrations/adapters/postgresql_adapter"

# modules
require_relative "strong_migrations/checks"
require_relative "strong_migrations/safe_methods"
require_relative "strong_migrations/checker"
require_relative "strong_migrations/database_tasks"
require_relative "strong_migrations/migration"
require_relative "strong_migrations/migrator"
require_relative "strong_migrations/version"

# integrations
require_relative "strong_migrations/railtie" if defined?(Rails)

module StrongMigrations
  class Error < StandardError; end
  class UnsafeMigration < Error; end
  class UnsupportedVersion < Error; end

  class << self
    attr_accessor :auto_analyze, :start_after, :checks, :error_messages,
      :target_postgresql_version, :target_mysql_version, :target_mariadb_version,
      :enabled_checks, :lock_timeout, :statement_timeout, :check_down, :target_version,
      :safe_by_default, :target_sql_mode, :lock_timeout_retries, :lock_timeout_retry_delay,
      :alphabetize_schema
    attr_writer :lock_timeout_limit
  end
  self.auto_analyze = false
  self.start_after = 0
  self.lock_timeout_retries = 0
  self.lock_timeout_retry_delay = 10 # seconds
  self.checks = []
  self.safe_by_default = false
  self.check_down = false
  self.alphabetize_schema = false

  # private
  def self.developer_env?
    env == "development" || env == "test"
  end

  # private
  def self.env
    if defined?(Rails.env)
      Rails.env
    else
      # default to production for safety
      ENV["RACK_ENV"] || "production"
    end
  end

  def self.lock_timeout_limit
    unless defined?(@lock_timeout_limit)
      @lock_timeout_limit = developer_env? ? false : 10
    end
    @lock_timeout_limit
  end

  def self.add_check(&block)
    checks << block
  end

  def self.enable_check(check, start_after: nil)
    enabled_checks[check] = {start_after: start_after}
  end

  def self.disable_check(check)
    enabled_checks.delete(check)
  end

  def self.check_enabled?(check, version: nil)
    if enabled_checks[check]
      start_after = enabled_checks[check][:start_after] || StrongMigrations.start_after
      !version || version > start_after
    else
      false
    end
  end
end

# load error messages
require_relative "strong_migrations/error_messages"

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migration.prepend(StrongMigrations::Migration)
  ActiveRecord::Migrator.prepend(StrongMigrations::Migrator)

  if defined?(ActiveRecord::Tasks::DatabaseTasks)
    ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(StrongMigrations::DatabaseTasks)
  end

  require_relative "strong_migrations/schema_dumper"
  ActiveRecord::SchemaDumper.prepend(StrongMigrations::SchemaDumper)
end
