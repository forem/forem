namespace :release do
  desc "Run migrations only if there are pending migrations (acquires advisory lock only when needed)"
  task migrate_if_pending: :environment do
    # Grab the migration context from ActiveRecord. In Rails 7+, `migration_context`
    # knows about your `db/migrate` folder and the schema_migrations table.
    migration_context = ActiveRecord::Base.connection.migration_context

    if migration_context.needs_migration?
      puts "[release] ⏳ Pending migrations detected. Running `db:migrate`…"
      # Invoke the normal Rails migrations. Because we are invoking a Rake task, 
      # it will obtain the advisory lock, run only the pending migrations, then release.
      Rake::Task["db:migrate"].invoke
    else
      puts "[release] ✅ No pending migrations. Skipping `db:migrate`."
    end
  end
end