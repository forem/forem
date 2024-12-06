ActiveRecord::Migration.verbose = false
ActiveRecord::Base.logger = Logger.new(nil)

if ActiveRecord::VERSION::MAJOR >= 6
  ActiveRecord::MigrationContext.new(
        File.expand_path('../../rails_app/db/migrate/', __FILE__),
        ActiveRecord::Base.connection.schema_migration
      ).migrate
elsif defined? ActiveRecord::MigrationContext # rails >= 5.2
  ActiveRecord::MigrationContext.new(File.expand_path('../../rails_app/db/migrate/', __FILE__)).migrate
else
  ActiveRecord::Migrator.migrate(File.expand_path('../../rails_app/db/migrate/', __FILE__))
end
