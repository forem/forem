namespace :release do
  desc "Run migrations only if there are pending migrations (acquires advisory lock only when needed)"
  task migrate_if_pending: :environment do
    migration_context = if ActiveRecord::Base.connection_pool.respond_to?(:migration_context)
                          ActiveRecord::Base.connection_pool.migration_context
                        else
                          ActiveRecord::Base.connection.migration_context
                        end

    Rake::Task["db:migrate"].invoke if migration_context.needs_migration?
  end
end
