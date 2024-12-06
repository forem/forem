# dependencies
require "active_support"

# stdlib
require "forwardable"

# methods
require_relative "pghero/methods/basic"
require_relative "pghero/methods/connections"
require_relative "pghero/methods/constraints"
require_relative "pghero/methods/explain"
require_relative "pghero/methods/indexes"
require_relative "pghero/methods/kill"
require_relative "pghero/methods/maintenance"
require_relative "pghero/methods/queries"
require_relative "pghero/methods/query_stats"
require_relative "pghero/methods/replication"
require_relative "pghero/methods/sequences"
require_relative "pghero/methods/settings"
require_relative "pghero/methods/space"
require_relative "pghero/methods/suggested_indexes"
require_relative "pghero/methods/system"
require_relative "pghero/methods/tables"
require_relative "pghero/methods/users"

require_relative "pghero/database"
require_relative "pghero/engine" if defined?(Rails)
require_relative "pghero/version"

module PgHero
  autoload :Connection, "pghero/connection"
  autoload :Stats, "pghero/stats"
  autoload :QueryStats, "pghero/query_stats"
  autoload :SpaceStats, "pghero/space_stats"

  class Error < StandardError; end
  class NotEnabled < Error; end

  MUTEX = Mutex.new

  # settings
  class << self
    attr_accessor :long_running_query_sec, :slow_query_ms, :slow_query_calls, :explain_timeout_sec, :total_connections_threshold, :cache_hit_rate_threshold, :env, :show_migrations, :config_path, :filter_data
  end
  self.long_running_query_sec = (ENV["PGHERO_LONG_RUNNING_QUERY_SEC"] || 60).to_i
  self.slow_query_ms = (ENV["PGHERO_SLOW_QUERY_MS"] || 20).to_i
  self.slow_query_calls = (ENV["PGHERO_SLOW_QUERY_CALLS"] || 100).to_i
  self.explain_timeout_sec = (ENV["PGHERO_EXPLAIN_TIMEOUT_SEC"] || 10).to_f
  self.total_connections_threshold = (ENV["PGHERO_TOTAL_CONNECTIONS_THRESHOLD"] || 500).to_i
  self.cache_hit_rate_threshold = 99
  self.env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
  self.show_migrations = true
  self.config_path = ENV["PGHERO_CONFIG_PATH"] || "config/pghero.yml"
  self.filter_data = ENV["PGHERO_FILTER_DATA"].to_s.size > 0

  class << self
    extend Forwardable
    def_delegators :primary_database, :aws_access_key_id, :analyze, :analyze_tables, :autoindex, :autovacuum_danger,
      :best_index, :blocked_queries, :connections, :connection_sources, :connection_states, :connection_stats,
      :cpu_usage, :create_user, :database_size, :aws_db_instance_identifier, :disable_query_stats, :drop_user,
      :duplicate_indexes, :enable_query_stats, :explain, :historical_query_stats_enabled?, :index_caching,
      :index_hit_rate, :index_usage, :indexes, :invalid_constraints, :invalid_indexes, :kill, :kill_all, :kill_long_running_queries,
      :last_stats_reset_time, :long_running_queries, :maintenance_info, :missing_indexes, :query_stats,
      :query_stats_available?, :query_stats_enabled?, :query_stats_extension_enabled?, :query_stats_readable?,
      :rds_stats, :read_iops_stats, :aws_region, :relation_sizes, :replica?, :replication_lag, :replication_lag_stats,
      :reset_query_stats, :reset_stats, :running_queries, :aws_secret_access_key, :sequence_danger, :sequences, :settings,
      :slow_queries, :space_growth, :ssl_used?, :stats_connection, :suggested_indexes, :suggested_indexes_by_query,
      :suggested_indexes_enabled?, :system_stats_enabled?, :table_caching, :table_hit_rate, :table_stats,
      :total_connections, :transaction_id_danger, :unused_indexes, :unused_tables, :write_iops_stats

    def time_zone=(time_zone)
      @time_zone = time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone.to_s]
    end

    def time_zone
      @time_zone || Time.zone
    end

    # use method instead of attr_accessor to ensure
    # this works if variable set after PgHero is loaded
    def username
      @username ||= config["username"] || ENV["PGHERO_USERNAME"]
    end

    # use method instead of attr_accessor to ensure
    # this works if variable set after PgHero is loaded
    def password
      @password ||= config["password"] || ENV["PGHERO_PASSWORD"]
    end

    # config pattern for https://github.com/ankane/pghero/issues/424
    def stats_database_url
      @stats_database_url ||= (file_config || {})["stats_database_url"] || ENV["PGHERO_STATS_DATABASE_URL"]
    end

    # private
    def explain_enabled?
      explain_mode.nil? || explain_mode == true || explain_mode == "analyze"
    end

    # private
    def explain_mode
      @config["explain"]
    end

    def visualize_url
      @visualize_url ||= config["visualize_url"] || ENV["PGHERO_VISUALIZE_URL"] || "https://tatiyants.com/pev/#/plans/new"
    end

    def config
      @config ||= file_config || default_config
    end

    # private
    def file_config
      unless defined?(@file_config)
        require "erb"
        require "yaml"

        path = config_path

        config_file_exists = File.exist?(path)

        config = YAML.safe_load(ERB.new(File.read(path)).result, aliases: true) if config_file_exists
        config ||= {}

        @file_config =
          if config[env]
            config[env]
          elsif config["databases"] # preferred format
            config
          elsif config_file_exists
            raise "Invalid config file"
          else
            nil
          end
      end

      @file_config
    end

    # private
    def default_config
      databases = {}

      unless ENV["PGHERO_DATABASE_URL"]
        ActiveRecord::Base.configurations.configs_for(env_name: env, include_replicas_key => true).each do |db|
          databases[db.send(spec_name_key)] = {"spec" => db.send(spec_name_key)}
        end
      end

      if databases.empty?
        databases["primary"] = {
          "url" => ENV["PGHERO_DATABASE_URL"] || default_connection_config
        }
      end

      if databases.size == 1
        databases.values.first.merge!(
          "aws_db_instance_identifier" => ENV["PGHERO_DB_INSTANCE_IDENTIFIER"],
          "gcp_database_id" => ENV["PGHERO_GCP_DATABASE_ID"],
          "azure_resource_id" => ENV["PGHERO_AZURE_RESOURCE_ID"]
        )
      end

      {
        "databases" => databases
      }
    end

    # private
    def default_connection_config
      connection_config(ActiveRecord::Base) if ActiveRecord::VERSION::STRING.to_f < 7.1
    end

    # ensure we only have one copy of databases
    # so there's only one connection pool per database
    def databases
      unless defined?(@databases)
        # only use mutex on initialization
        MUTEX.synchronize do
          # return if another process initialized while we were waiting
          return @databases if defined?(@databases)

          @databases = config["databases"].map { |id, c| [id.to_sym, Database.new(id, c)] }.to_h
        end
      end

      @databases
    end

    def primary_database
      databases.values.first
    end

    def capture_query_stats(verbose: false)
      each_database do |database|
        next unless database.capture_query_stats?
        puts "Capturing query stats for #{database.id}..." if verbose
        database.capture_query_stats(raise_errors: true)
      end
    end

    def capture_space_stats(verbose: false)
      each_database do |database|
        puts "Capturing space stats for #{database.id}..." if verbose
        database.capture_space_stats
      end
    end

    def analyze_all(**options)
      each_database do |database|
        next if database.replica?
        database.analyze_tables(**options)
      end
    end

    def autoindex_all(create: false, verbose: true)
      each_database do |database|
        puts "Autoindexing #{database.id}..." if verbose
        database.autoindex(create: create)
      end
    end

    def pretty_size(value)
      ActiveSupport::NumberHelper.number_to_human_size(value, precision: 3)
    end

    # delete previous stats
    # go database by database to use an index
    # stats for old databases are not cleaned up since we can't use an index
    def clean_query_stats(before: nil)
      each_database do |database|
        database.clean_query_stats(before: before)
      end
    end

    def clean_space_stats(before: nil)
      each_database do |database|
        database.clean_space_stats(before: before)
      end
    end

    # private
    def connection_config(model)
      ActiveRecord::VERSION::STRING.to_f >= 6.1 ? model.connection_db_config.configuration_hash : model.connection_config
    end

    # private
    # Rails 6.1 deprecates `spec_name` for `name`
    # https://github.com/rails/rails/pull/38536
    def spec_name_key
      ActiveRecord::VERSION::STRING.to_f >= 6.1 ? :name : :spec_name
    end

    # private
    # Rails 7.0 deprecates `include_replicas` for `include_hidden`
    def include_replicas_key
      ActiveRecord::VERSION::MAJOR >= 7 ? :include_hidden : :include_replicas
    end

    private

    def each_database
      first_error = nil

      databases.each do |_, database|
        begin
          yield database
        rescue => e
          puts "#{e.class.name}: #{e.message}"
          puts
          first_error ||= e
        end
      end

      raise first_error if first_error

      true
    end
  end
end
