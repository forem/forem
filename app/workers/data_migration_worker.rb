class DataMigrationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high_priority, retry: 5

  def perform
    RailsDataMigrations::Migrator.list_pending_migrations.sort_by(&:version).each do |m|
      run_migration(:up, m.version)
    end
  end

  private

  # adapted from https://github.com/OffgridElectric/rails-data-migrations/blob/18884e29412853ec13d94f6715acf6c7ff5d874b/lib/tasks/data_migrations.rake#L4
  def run_migration(direction, version)
    RailsDataMigrations::Migrator.run_migration(
      direction,
      RailsDataMigrations::Migrator.migrations_path,
      version.to_i,
    )
  rescue StandardError => e
    Honeybadger.notify(e, context: { migration_version: version })
  end
end
