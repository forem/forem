module StrongMigrations
  module Migrator
    def ddl_transaction(migration, *args)
      return super unless StrongMigrations.lock_timeout_retries > 0 && use_transaction?(migration)

      # handle MigrationProxy class
      migration = migration.send(:migration) if migration.respond_to?(:migration, true)

      # retry migration since the entire transaction needs to be rerun
      checker = migration.send(:strong_migrations_checker)
      checker.retry_lock_timeouts(check_committed: true) do
        # failed transaction reverts timeout, so need to re-apply
        checker.timeouts_set = false

        super(migration, *args)
      end
    end
  end
end
