module StrongMigrations
  class Checker
    include Checks
    include SafeMethods

    attr_accessor :direction, :transaction_disabled, :timeouts_set

    class << self
      attr_accessor :safe
    end

    def initialize(migration)
      @migration = migration
      @new_tables = []
      @new_columns = []
      @timeouts_set = false
      @committed = false
    end

    def self.safety_assured
      previous_value = safe
      begin
        self.safe = true
        yield
      ensure
        self.safe = previous_value
      end
    end

    def perform(method, *args)
      check_version_supported
      set_timeouts
      check_lock_timeout

      if !safe? || safe_by_default_method?(method)
        # TODO better pattern
        # see checks.rb for methods
        case method
        when :add_check_constraint
          check_add_check_constraint(*args)
        when :add_column
          check_add_column(*args)
        when :add_exclusion_constraint
          check_add_exclusion_constraint(*args)
        when :add_foreign_key
          check_add_foreign_key(*args)
        when :add_index
          check_add_index(*args)
        when :add_reference, :add_belongs_to
          check_add_reference(method, *args)
        when :add_unique_constraint
          check_add_unique_constraint(*args)
        when :change_column
          check_change_column(*args)
        when :change_column_default
          check_change_column_default(*args)
        when :change_column_null
          check_change_column_null(*args)
        when :change_table
          check_change_table
        when :create_join_table
          check_create_join_table(*args)
        when :create_table
          check_create_table(*args)
        when :execute
          check_execute
        when :remove_column, :remove_columns, :remove_timestamps, :remove_reference, :remove_belongs_to
          check_remove_column(method, *args)
        when :remove_index
          check_remove_index(*args)
        when :rename_column
          check_rename_column
        when :rename_table
          check_rename_table
        when :validate_check_constraint
          check_validate_check_constraint
        when :validate_foreign_key
          check_validate_foreign_key
        when :commit_db_transaction
          # if committed, likely no longer in DDL transaction
          # and no longer eligible to be retried at migration level
          # okay to have false positives
          @committed = true
        end

        if !safe?
          # custom checks
          StrongMigrations.checks.each do |check|
            @migration.instance_exec(method, args, &check)
          end
        end
      end

      result =
        if retry_lock_timeouts?(method)
          # TODO figure out how to handle methods that generate multiple statements
          # like add_reference(table, ref, index: {algorithm: :concurrently})
          # lock timeout after first statement will cause retry to fail
          retry_lock_timeouts { yield }
        else
          yield
        end

      # outdated statistics + a new index can hurt performance of existing queries
      if StrongMigrations.auto_analyze && direction == :up && method == :add_index
        adapter.analyze_table(args[0])
      end

      result
    end

    def retry_lock_timeouts(check_committed: false)
      retries = 0
      begin
        yield
      rescue ActiveRecord::LockWaitTimeout => e
        if retries < StrongMigrations.lock_timeout_retries && !(check_committed && @committed)
          retries += 1
          delay = StrongMigrations.lock_timeout_retry_delay
          @migration.say("Lock timeout. Retrying in #{delay} seconds...")
          sleep(delay)
          retry
        end
        raise e
      end
    end

    def version_safe?
      version && version <= StrongMigrations.start_after
    end

    private

    def check_version_supported
      return if defined?(@version_checked)

      min_version = adapter.min_version
      if min_version
        version = adapter.server_version
        if version < Gem::Version.new(min_version)
          raise UnsupportedVersion, "#{adapter.name} version (#{version}) not supported in this version of Strong Migrations (#{StrongMigrations::VERSION})"
        end
      end

      @version_checked = true
    end

    def set_timeouts
      return if @timeouts_set

      if StrongMigrations.statement_timeout
        adapter.set_statement_timeout(StrongMigrations.statement_timeout)
      end
      if StrongMigrations.lock_timeout
        adapter.set_lock_timeout(StrongMigrations.lock_timeout)
      end

      @timeouts_set = true
    end

    def check_lock_timeout
      return if defined?(@lock_timeout_checked)

      if StrongMigrations.lock_timeout_limit
        adapter.check_lock_timeout(StrongMigrations.lock_timeout_limit)
      end

      @lock_timeout_checked = true
    end

    def safe?
      self.class.safe || ENV["SAFETY_ASSURED"] || (direction == :down && !StrongMigrations.check_down) || version_safe? || @migration.reverting?
    end

    def version
      @migration.version
    end

    def adapter
      @adapter ||= begin
        cls =
          case connection.adapter_name
          when /postg/i # PostgreSQL, PostGIS
            Adapters::PostgreSQLAdapter
          when /mysql|trilogy/i
            if connection.try(:mariadb?)
              Adapters::MariaDBAdapter
            else
              Adapters::MySQLAdapter
            end
          else
            Adapters::AbstractAdapter
          end

        cls.new(self)
      end
    end

    def connection
      @migration.connection
    end

    def retry_lock_timeouts?(method)
      (
        StrongMigrations.lock_timeout_retries > 0 &&
        !in_transaction? &&
        method != :transaction
      )
    end
  end
end
