# https://github.com/ankane/strong_migrations#existing-migrations
StrongMigrations.start_after = 20_200_106_074_859

# https://github.com/ankane/strong_migrations#removing-an-index-non-concurrently
StrongMigrations.enable_check(:remove_index)

# https://github.com/ankane/strong_migrations#target-version
StrongMigrations.target_postgresql_version = 11

# https://github.com/ankane/strong_migrations#down-migrations--rollbacks
StrongMigrations.check_down = true

module StrongMigrations
  def self.temporarily_disable_check(check)
    disable_check check

    yield
  ensure
    enable_check check
  end
end
