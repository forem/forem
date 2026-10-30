module CiKnapsackProSkipShallowFetch
  def shallow_repository?
    false
  end
end

if ENV["CI"] && !defined?(CiSchemaRailtie)
  ENV["RAILS_ENV"] = "test"
  ENV["RUBY_DEBUG_ENABLE"] ||= "0"
  ENV["RUBY_DEBUG_FORK_MODE"] ||= "parent"
  require "rails"

  class CiSchemaRailtie < Rails::Railtie
    config.after_initialize do
      if defined?(KnapsackPro::RepositoryAdapters::GitAdapter)
        KnapsackPro::RepositoryAdapters::GitAdapter.prepend(CiKnapsackProSkipShallowFetch)
      end

      ActiveRecord::Base.with_connection do |conn|
        next if conn.data_source_exists?("schema_migrations")

        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, Rails.root.join("db/schema.rb"))
        end
        ActiveRecord.maintain_test_schema = false
      end
    end
  end

  if defined?(KnapsackPro::Adapters::RSpecAdapter)
    module CiKnapsackProForkedDetector
      def test_file_cases_for(slow_test_files)
        KnapsackPro.logger.info(
          "Generating RSpec test examples JSON report in-memory for #{slow_test_files.size} slow test files.",
        )

        spec_dir = File.expand_path("../..", __dir__)
        $LOAD_PATH.unshift(spec_dir) unless $LOAD_PATH.include?(spec_dir)
        require "rspec/core"
        require "rails_helper"

        pid = Process.fork do
          ENV.delete("SPEC_OPTS")
          ActiveRecord::Base.connection_handler.clear_all_connections!(:all)
          KnapsackPro::TestCaseDetectors::RSpecTestExampleDetector.new.generate_json_report
          Process.exit!(0)
        end
        _, status = Process.wait2(pid)
        raise "Could not generate JSON report for RSpec" unless status.success?

        KnapsackPro::TestCaseDetectors::RSpecTestExampleDetector.new.test_file_example_paths
      end
    end

    KnapsackPro::Adapters::RSpecAdapter.singleton_class.prepend(CiKnapsackProForkedDetector)
  end

end
