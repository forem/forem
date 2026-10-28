module ReleaseMigrate
  def self.needs_migration?
    migration_context = if ActiveRecord::Base.connection_pool.respond_to?(:migration_context)
                          ActiveRecord::Base.connection_pool.migration_context
                        else
                          ActiveRecord::Base.connection.migration_context
                        end
    migration_context.needs_migration?
  rescue StandardError => e
    if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
      Rails.logger.warn("[release:migrate_if_pending] Falling back to db:migrate: #{e.class}: #{e.message}")
    end
    true
  end
end

namespace :release do
  desc "Run migrations only if there are pending migrations (acquires advisory lock only when needed)"
  task migrate_if_pending: :environment do
    Rake::Task["db:migrate"].invoke if ReleaseMigrate.needs_migration?
  end
end
