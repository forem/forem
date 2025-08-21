namespace :release do
  desc "Run migrations (always runs db:migrate for production reliability)"
  task migrate_if_pending: :environment do
    puts "[release] 🔄 Running database migrations..."
    # Always run migrations for production reliability
    # This ensures the database is in the correct state regardless of migration status
    Rake::Task["db:migrate"].invoke
    puts "[release] ✅ Database migrations completed successfully."
  end
end
