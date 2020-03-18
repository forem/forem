# https://github.com/ankane/strong_migrations#existing-migrations
StrongMigrations.start_after = 20_200_106_074_859

# https://github.com/ankane/strong_migrations#removing-an-index
StrongMigrations.enable_check(:remove_index)

# https://github.com/ankane/strong_migrations#target-version
StrongMigrations.target_postgresql_version = 11
