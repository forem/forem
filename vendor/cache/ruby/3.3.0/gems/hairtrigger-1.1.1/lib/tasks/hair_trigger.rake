namespace :db do
  desc "Creates a database migration for any newly created/modified/deleted triggers in the models"
  task :generate_trigger_migration => :environment do
    if file_name = HairTrigger.generate_migration
      puts "Generated #{file_name}"
    else
      puts "Nothing to do"
    end
  end

  namespace :schema do
    desc "Create a db/schema.rb file that can be portably used against any DB supported by AR"
    task :dump => :environment do
      format = ActiveRecord.respond_to?(:schema_format) ? ActiveRecord.schema_format : ActiveRecord::Base.schema_format
      next unless format == :ruby

      require 'active_record/schema_dumper'

      databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

      ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
        db_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: name)
        connection_pool = ActiveRecord::Base.establish_connection(db_config)

        filename = dump_filename(db_config.name)
        ActiveRecord::SchemaDumper.previous_schema = File.exist?(filename) ? File.read(filename) : nil

        File.open(filename, "w") do |file|
          ActiveRecord::SchemaDumper.dump(connection_pool.connection, file)
        end
      end

      Rake::Task["db:schema:dump"].reenable
    end

    def schema_file_type(format)
      case format
        when :ruby
          "schema.rb"
        when :sql
          "structure.sql"
      end
    end

    # code adopted from activerecord/lib/active_record/tasks/database_tasks.rb#L441
    def dump_filename(db_config_name)
      format = ActiveRecord.respond_to?(:schema_format) ? ActiveRecord.schema_format : ActiveRecord::Base.schema_format
      filename = if ActiveRecord::Base.configurations.primary?(db_config_name)
                   schema_file_type(format)
                 else
                   "#{db_config_name}_#{schema_file_type(format)}"
                 end

      ENV["SCHEMA"] || File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, filename)
    end
  end
end
