module PgHero
  class Database
    include Methods::Basic
    include Methods::Connections
    include Methods::Constraints
    include Methods::Explain
    include Methods::Indexes
    include Methods::Kill
    include Methods::Maintenance
    include Methods::Queries
    include Methods::QueryStats
    include Methods::Replication
    include Methods::Sequences
    include Methods::Settings
    include Methods::Space
    include Methods::SuggestedIndexes
    include Methods::System
    include Methods::Tables
    include Methods::Users

    attr_reader :id, :config

    def initialize(id, config)
      @id = id
      @config = config || {}

      # preload model to ensure only one connection pool
      # this doesn't actually start any connections
      @adapter_checked = false
      @connection_model = build_connection_model
    end

    def name
      @name ||= @config["name"] || id.titleize
    end

    def capture_query_stats?
      config["capture_query_stats"] != false
    end

    def cache_hit_rate_threshold
      (config["cache_hit_rate_threshold"] || PgHero.config["cache_hit_rate_threshold"] || PgHero.cache_hit_rate_threshold).to_i
    end

    def total_connections_threshold
      (config["total_connections_threshold"] || PgHero.config["total_connections_threshold"] || PgHero.total_connections_threshold).to_i
    end

    def slow_query_ms
      (config["slow_query_ms"] || PgHero.config["slow_query_ms"] || PgHero.slow_query_ms).to_i
    end

    def slow_query_calls
      (config["slow_query_calls"] || PgHero.config["slow_query_calls"] || PgHero.slow_query_calls).to_i
    end

    def explain_timeout_sec
      (config["explain_timeout_sec"] || PgHero.config["explain_timeout_sec"] || PgHero.explain_timeout_sec).to_f
    end

    def long_running_query_sec
      (config["long_running_query_sec"] || PgHero.config["long_running_query_sec"] || PgHero.long_running_query_sec).to_i
    end

    # defaults to 100 megabytes
    def index_bloat_bytes
      (config["index_bloat_bytes"] || PgHero.config["index_bloat_bytes"] || 104857600).to_i
    end

    def aws_access_key_id
      config["aws_access_key_id"] || PgHero.config["aws_access_key_id"] || ENV["PGHERO_ACCESS_KEY_ID"] || ENV["AWS_ACCESS_KEY_ID"]
    end

    def aws_secret_access_key
      config["aws_secret_access_key"] || PgHero.config["aws_secret_access_key"] || ENV["PGHERO_SECRET_ACCESS_KEY"] || ENV["AWS_SECRET_ACCESS_KEY"]
    end

    def aws_region
      config["aws_region"] || PgHero.config["aws_region"] || ENV["PGHERO_REGION"] || ENV["AWS_REGION"] || (defined?(Aws) && Aws.config[:region]) || "us-east-1"
    end

    # environment variable is only used if no config file
    def aws_db_instance_identifier
      @aws_db_instance_identifier ||= config["aws_db_instance_identifier"] || config["db_instance_identifier"]
    end

    # environment variable is only used if no config file
    def gcp_database_id
      @gcp_database_id ||= config["gcp_database_id"]
    end

    # environment variable is only used if no config file
    def azure_resource_id
      @azure_resource_id ||= config["azure_resource_id"]
    end

    # must check keys for booleans
    def filter_data
      unless defined?(@filter_data)
        @filter_data =
          if config.key?("filter_data")
            config["filter_data"]
          elsif PgHero.config.key?("filter_data")
            PgHero.config.key?("filter_data")
          else
            PgHero.filter_data
          end

        if @filter_data
          begin
            require "pg_query"
          rescue LoadError
            raise Error, "pg_query required for filter_data"
          end
        end
      end

      @filter_data
    end

    private

    # check adapter lazily
    def connection_model
      unless @adapter_checked
        # rough check for Postgres adapter
        # keep this message generic so it's useful
        # when empty url set in Docker image pghero.yml
        unless @connection_model.connection.adapter_name =~ /postg/i
          raise Error, "Invalid connection URL"
        end
        @adapter_checked = true
      end

      @connection_model
    end

    # just return the model
    # do not start a connection
    def build_connection_model
      url = config["url"]

      # resolve spec
      if !url && config["spec"]
        config_options = {env_name: PgHero.env, PgHero.spec_name_key => config["spec"], PgHero.include_replicas_key => true}
        resolved = ActiveRecord::Base.configurations.configs_for(**config_options)
        raise Error, "Spec not found: #{config["spec"]}" unless resolved
        url = ActiveRecord::VERSION::STRING.to_f >= 6.1 ? resolved.configuration_hash : resolved.config
      end

      url = url.dup

      Class.new(PgHero::Connection) do
        def self.name
          "PgHero::Connection::Database#{object_id}"
        end

        case url
        when String
          url = "#{url}#{url.include?("?") ? "&" : "?"}connect_timeout=5" unless url.include?("connect_timeout=")
        when Hash
          url[:connect_timeout] ||= 5
        end
        establish_connection url if url
      end
    end
  end
end
