require "rails_helper"
require "puma/configuration"

RSpec.describe ServerWarmup, type: :lib do
  after do
    described_class.reset_state!
  end

  describe ".warmup_enabled?" do
    it "returns false by default in the test environment" do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("PUMA_WARMUP_ENABLED").and_return(false)

      expect(described_class.warmup_enabled?).to be(false)
    end

    it "returns false by default in the development environment" do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("PUMA_WARMUP_ENABLED").and_return(false)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))

      expect(described_class.warmup_enabled?).to be(false)
    end

    it "returns true by default in the production environment" do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("PUMA_WARMUP_ENABLED").and_return(false)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

      expect(described_class.warmup_enabled?).to be(true)
    end

    it "returns true when PUMA_WARMUP_ENABLED is set to 'true'" do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("PUMA_WARMUP_ENABLED").and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PUMA_WARMUP_ENABLED").and_return("true")

      expect(described_class.warmup_enabled?).to be(true)
    end

    it "returns false when PUMA_WARMUP_ENABLED is set to 'false' even in production" do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("PUMA_WARMUP_ENABLED").and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PUMA_WARMUP_ENABLED").and_return("false")
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

      expect(described_class.warmup_enabled?).to be(false)
    end
  end

  describe ".preload_model_schemas!" do
    it "preloads schema reflection, primary keys, and attribute methods for core models" do
      described_class.preload_model_schemas!

      expect(User.__send__(:schema_loaded?)).to be(true)
      expect(User.attribute_methods_generated?).to be(true)
      expect(Article.__send__(:schema_loaded?)).to be(true)
      expect(Article.attribute_methods_generated?).to be(true)
      expect(Subforem.__send__(:schema_loaded?)).to be(true)
      expect(Billboard.__send__(:schema_loaded?)).to be(true)
    end

    it "preloads schema cache entries for auxiliary join tables" do
      described_class.preload_model_schemas!

      schema_cache = ActiveRecord::Base.connection_pool.schema_cache
      expect(schema_cache.columns_hash("users_roles")).to be_present
      expect(schema_cache.columns_hash("flipper_features")).to be_present
      expect(schema_cache.columns_hash("flipper_gates")).to be_present
    end

    it "does not raise when the database is unavailable" do
      allow(described_class).to receive(:database_available?).and_return(false)

      expect { described_class.preload_model_schemas! }.not_to raise_error
    end

    it "logs errors at error level and continues preloading when an individual model raises" do
      failing_model = Class.new(ApplicationRecord) do
        self.table_name = "users"

        def self.load_schema
          raise ActiveRecord::StatementInvalid, "simulated schema error"
        end
      end

      allow(described_class).to receive(:models_to_preload).and_return([failing_model, Article])
      allow(Rails.logger).to receive(:error)

      expect { described_class.preload_model_schemas! }.not_to raise_error
      expect(Article.__send__(:schema_loaded?)).to be(true)
      expect(Rails.logger).to have_received(:error).with(
        a_string_including("[ServerWarmup] Schema preload failed", "simulated schema error"),
      )
    end
  end

  describe ".preload_routes_and_i18n!" do
    it "eager-loads routes and I18n backend" do
      allow(Rails.application.routes).to receive(:eager_load!).and_call_original
      allow(I18n.backend).to receive(:eager_load!).and_call_original

      described_class.preload_routes_and_i18n!

      expect(Rails.application.routes).to have_received(:eager_load!).once
      expect(I18n.backend).to have_received(:eager_load!).once
    end

    it "reloads routes first if route set is empty" do
      allow(Rails.application.routes.routes).to receive(:empty?).and_return(true)
      allow(Rails.application).to receive(:reload_routes!)
      allow(Rails.application.routes).to receive(:eager_load!)

      described_class.preload_routes_and_i18n!

      expect(Rails.application).to have_received(:reload_routes!).once
      expect(Rails.application.routes).to have_received(:eager_load!).once
    end

    it "logs errors without raising if route eager-loading fails" do
      allow(Rails.application.routes).to receive(:eager_load!).and_raise(StandardError, "route error")
      allow(Rails.logger).to receive(:error)

      expect { described_class.preload_routes_and_i18n! }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with(
        a_string_including("[ServerWarmup] Routes and I18n preload failed", "route error"),
      )
    end
  end

  describe ".preload_view_templates!" do
    it "populates unbound templates and compiles templates into the shared view context class" do
      resolver = ActionController::Base.view_paths.paths.first
      template_path = ActionView::TemplatePath.parse("articles/index")
      allow(resolver).to receive(:all_template_paths).and_return([template_path])
      allow(ActionController::Base.view_paths).to receive(:paths).and_return([resolver])

      compiled_count = described_class.preload_view_templates!

      expect(compiled_count).to be >= 1
      unbound_cache = resolver.instance_variable_get(:@unbound_templates)
      expect(unbound_cache[template_path.virtual]).to be_present
      compiled_template = unbound_cache[template_path.virtual].first.bind_locals([])
      expect(compiled_template.instance_variable_get(:@compiled)).to be(true)
      expect(ApplicationController.view_context_class.empty.respond_to?(compiled_template.method_name)).to be(true)
    end

    it "logs an error and continues when an individual template fails to compile" do
      bad_unbound = Class.new do
        def bind_locals(_locals)
          raise StandardError, "broken template syntax"
        end
      end.new
      fake_cache = Class.new do
        def initialize(item)
          @item = item
        end

        def compute_if_absent(_key)
          [@item]
        end
      end.new(bad_unbound)
      fake_resolver = Class.new do
        def initialize(cache, template_path)
          @unbound_templates = cache
          @template_path = template_path
        end

        def all_template_paths
          [@template_path]
        end
      end.new(fake_cache, ActionView::TemplatePath.parse("broken/view"))

      allow(ActionController::Base.view_paths).to receive(:paths).and_return([fake_resolver])
      allow(Rails.logger).to receive(:error)

      expect(described_class.preload_view_templates!).to eq(0)
      expect(Rails.logger).to have_received(:error).with(
        a_string_including("[ServerWarmup] Template compile failed for broken/view", "broken template syntax"),
      )
    end
  end

  describe ".warm_database_connections!" do
    it "checks out, verifies, and checks back in the requested number of connections" do
      mock_conn1 = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, verify!: true)
      mock_conn2 = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, verify!: true)
      mock_pool = instance_double(
        ActiveRecord::ConnectionAdapters::ConnectionPool,
        size: 5,
      )
      allow(mock_pool).to receive(:checkout).and_return(mock_conn1, mock_conn2)
      allow(mock_pool).to receive(:checkin)
      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(mock_pool)

      warmed = described_class.warm_database_connections!(2)

      expect(warmed).to eq(2)
      expect(mock_conn1).to have_received(:verify!).once
      expect(mock_conn2).to have_received(:verify!).once
      expect(mock_pool).to have_received(:checkin).with(mock_conn1).once
      expect(mock_pool).to have_received(:checkin).with(mock_conn2).once
    end

    it "checks back in already checked-out connections and logs error if checkout fails" do
      mock_conn1 = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, verify!: true)
      mock_pool = instance_double(
        ActiveRecord::ConnectionAdapters::ConnectionPool,
        size: 5,
      )
      call_count = 0
      allow(mock_pool).to receive(:checkout) do
        call_count += 1
        raise ActiveRecord::ConnectionTimeoutError, "timeout" if call_count > 1

        mock_conn1
      end
      allow(mock_pool).to receive(:checkin)
      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(mock_pool)
      allow(Rails.logger).to receive(:error)

      expect(described_class.warm_database_connections!(2)).to eq(0)
      expect(mock_pool).to have_received(:checkin).with(mock_conn1).once
      expect(Rails.logger).to have_received(:error).with(
        a_string_including("[ServerWarmup] Database connection pool warmup failed"),
      )
    end
  end

  describe ".warm_redis_cache_connection!" do
    it "pops, pings, and pushes back multiple connections when Rails.cache.redis has a TimedStack" do
      conn1 = Class.new do
        attr_reader :pinged

        def ping
          @pinged = true
        end
      end.new
      conn2 = Class.new do
        attr_reader :pinged

        def ping
          @pinged = true
        end
      end.new
      fake_stack = Class.new do
        attr_reader :pushed

        def initialize(conns)
          @conns = conns.dup
          @pushed = []
        end

        def pop(timeout: nil) # rubocop:disable Lint/UnusedMethodArgument
          @conns.shift
        end

        def push(conn)
          @pushed << conn
        end
      end.new([conn1, conn2])

      redis_pool = Class.new do
        def initialize(stack)
          @available = stack
        end

        def size
          5
        end
      end.new(fake_stack)

      cache_with_pool = Class.new do
        attr_reader :redis

        def initialize(redis)
          @redis = redis
        end

        def delete(_key); end
      end.new(redis_pool)

      allow(Rails).to receive(:cache).and_return(cache_with_pool)
      allow(Sidekiq).to receive(:redis)

      warmed = described_class.warm_redis_cache_connection!(2)

      expect(warmed).to eq(2)
      expect(conn1.pinged).to be(true)
      expect(conn2.pinged).to be(true)
      expect(fake_stack.pushed).to eq([conn1, conn2])
      expect(Sidekiq).to have_received(:redis).once
    end
  end

  describe ".warm_in_memory_caches!" do
    before do
      MemoryFirstCache.reset_memory_store!
      create(:subforem, domain: "dev.local", root: true, discoverable: true)
      Flipper.enable(:community_favorites)
    end

    after do
      Flipper.disable(:community_favorites)
      MemoryFirstCache.reset_memory_store!
    end

    it "warms Flipper, MemoryFirstCache Subforem keys, and clears RequestStore afterwards" do
      allow(Flipper).to receive(:preload).and_call_original

      described_class.warm_in_memory_caches!

      memory_store = MemoryFirstCache.__send__(:memory_store)
      expect(Flipper).to have_received(:preload).with(array_including(:community_favorites))
      expect(memory_store.read("memory_first:enabled_global_feature_flags")).to include("community_favorites")
      expect(memory_store.read("memory_first:subforem_default_id")).to be_present
      expect(memory_store.read("memory_first:subforem_root_id")).to be_present
      expect(memory_store.read("memory_first:subforem_domains")).to include("dev.local")
      expect(memory_store.read("memory_first:subforem_all_domains")).to include("dev.local")
      expect(memory_store.read("memory_first:subforem_id_by_domain_dev.local")).to be_present
      expect(RequestStore.store).to be_empty
    end

    it "warms Settings caches for global and subforem scopes" do
      allow(Settings::General).to receive(:all_settings).and_call_original

      described_class.warm_in_memory_caches!

      expect(Settings::General).to have_received(:all_settings).with(nil).at_least(:once)
    end
  end

  describe ".disconnect_parent_connections!" do
    after do
      ActiveRecord::Base.establish_connection
    end

    it "clears RequestStore, clears all ActiveRecord connections, and closes direct Redis client" do
      RequestStore.store[:warmup_test_key] = "present"
      redis_client = Class.new do
        attr_reader :closed

        def close
          @closed = true
        end
      end.new
      cache_with_redis = Class.new do
        attr_reader :redis

        def initialize(redis)
          @redis = redis
        end

        def delete(_key); end
      end.new(redis_client)

      allow(Rails).to receive(:cache).and_return(cache_with_redis)
      allow(ActiveRecord::Base.connection_handler).to receive(:clear_all_connections!).and_call_original

      described_class.disconnect_parent_connections!

      expect(RequestStore.store).to be_empty
      expect(ActiveRecord::Base.connection_handler).to have_received(:clear_all_connections!).with(:all)
      expect(redis_client.closed).to be(true)
    end

    it "closes pooled Redis connections via .with when Rails.cache.redis is a connection pool" do
      pooled_conn = Class.new do
        attr_reader :closed

        def close
          @closed = true
        end
      end.new
      redis_pool = Class.new do
        def initialize(conn)
          @conn = conn
        end

        def with
          yield @conn
        end
      end.new(pooled_conn)
      cache_with_pool = Class.new do
        attr_reader :redis

        def initialize(redis)
          @redis = redis
        end

        def delete(_key); end
      end.new(redis_pool)

      allow(Rails).to receive(:cache).and_return(cache_with_pool)

      described_class.disconnect_parent_connections!

      expect(pooled_conn.closed).to be(true)
    end

    it "logs an error without raising if closing Redis fails" do
      failing_redis = Class.new do
        def close
          raise Redis::BaseError, "simulated close failure"
        end
      end.new
      cache_with_failing_redis = Class.new do
        attr_reader :redis

        def initialize(redis)
          @redis = redis
        end

        def delete(_key); end
      end.new(failing_redis)

      allow(Rails).to receive(:cache).and_return(cache_with_failing_redis)
      allow(Rails.logger).to receive(:error)

      expect { described_class.disconnect_parent_connections! }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with(
        a_string_including("[ServerWarmup] Redis connection close failed", "simulated close failure"),
      )
    end
  end

  describe ".before_fork" do
    it "runs routes/i18n, view templates, schema preload, caches, and disconnects parent connections in ensure" do
      allow(described_class).to receive(:warmup_enabled?).and_return(true)
      allow(described_class).to receive(:preload_routes_and_i18n!)
      allow(described_class).to receive(:preload_view_templates!)
      allow(described_class).to receive(:preload_model_schemas!)
      allow(described_class).to receive(:warm_in_memory_caches!).and_raise(StandardError, "simulated error")
      allow(described_class).to receive(:disconnect_parent_connections!)
      allow(Rails.logger).to receive(:error)

      expect { described_class.before_fork }.not_to raise_error
      expect(described_class).to have_received(:preload_routes_and_i18n!).once
      expect(described_class).to have_received(:preload_view_templates!).once
      expect(described_class).to have_received(:preload_model_schemas!).once
      expect(described_class).to have_received(:disconnect_parent_connections!).once
      expect(Rails.logger).to have_received(:error).with(
        a_string_including("[ServerWarmup] before_fork warmup failed: StandardError: simulated error"),
      )
    end
  end

  describe ".on_worker_boot" do
    it "always establishes the ActiveRecord connection even when warmup is disabled" do
      allow(described_class).to receive(:warmup_enabled?).and_return(false)
      allow(ActiveRecord::Base).to receive(:establish_connection)

      described_class.on_worker_boot

      expect(ActiveRecord::Base).to have_received(:establish_connection).once
    end

    it "warms database connections, Redis cache, and in-memory caches when enabled" do
      allow(described_class).to receive(:warmup_enabled?).and_return(true)
      allow(ActiveRecord::Base).to receive(:establish_connection)
      allow(described_class).to receive(:warm_database_connections!)
      allow(described_class).to receive(:warm_redis_cache_connection!)
      allow(described_class).to receive(:warm_in_memory_caches!)
      allow(described_class).to receive(:start_preboot_keepalive!)

      described_class.on_worker_boot

      expect(ActiveRecord::Base).to have_received(:establish_connection).once
      expect(described_class).to have_received(:warm_database_connections!).once
      expect(described_class).to have_received(:warm_redis_cache_connection!).once
      expect(described_class).to have_received(:warm_in_memory_caches!).once
      expect(described_class).to have_received(:start_preboot_keepalive!).once
    end
  end

  describe ".start_preboot_keepalive! and traffic executor hook" do
    it "periodically refreshes database, Redis connections, and Flipper cache until stopped" do
      refresh_count = 0
      allow(described_class).to receive(:warm_database_connections!) { refresh_count += 1 }
      allow(described_class).to receive(:warm_redis_cache_connection!)
      allow(described_class).to receive(:warm_flipper_cache!)

      described_class.start_preboot_keepalive!(duration_seconds: 2, interval_seconds: 0.02)
      sleep 0.06
      described_class.stop_preboot_keepalive!

      expect(refresh_count).to be >= 1
      expect(described_class).to have_received(:warm_redis_cache_connection!).at_least(:once)
      expect(described_class).to have_received(:warm_flipper_cache!).at_least(:once)
      expect(described_class.traffic_received?).to be(false)
    end

    it "marks traffic_received and exits the keepalive thread when Rails.application.executor runs" do
      described_class.__send__(:register_traffic_hook!)
      allow(described_class).to receive(:warm_database_connections!)
      allow(described_class).to receive(:warm_redis_cache_connection!)
      allow(described_class).to receive(:warm_flipper_cache!)

      described_class.start_preboot_keepalive!(duration_seconds: 5, interval_seconds: 0.02)
      keepalive_thread = described_class.instance_variable_get(:@keepalive_thread)
      expect(keepalive_thread).to be_alive
      expect(described_class.traffic_received?).to be(false)

      Rails.application.executor.wrap do
        # Simulates the first live request entering the Rails executor
      end

      expect(described_class.traffic_received?).to be(true)
      expect(keepalive_thread.join(1)).to eq(keepalive_thread)
      expect(keepalive_thread).not_to be_alive
    end
  end

  describe "config/puma.rb integration" do
    let(:puma_config_path) { Rails.root.join("config/puma.rb").to_s }

    it "configures wait_for_less_busy_worker, worker_shutdown_timeout, and ServerWarmup hooks" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("WEB_CONCURRENCY", 2).and_return("2")

      config = Puma::Configuration.new do |user_config|
        user_config.instance_eval(File.read(puma_config_path), puma_config_path, 1)
      end
      config.load

      expect(config.options[:workers]).to eq(2)
      expect(config.options[:wait_for_less_busy_worker]).to eq(0.005)
      expect(config.options[:worker_shutdown_timeout]).to eq(25)
      expect(config.options[:nakayoshi_fork]).to be(true)
      expect(config.options[:preload_app]).to be(true)
      expect(config.options[:before_fork]).not_to be_empty
      expect(config.options[:before_worker_boot]).not_to be_empty
      expect(config.options[:before_worker_shutdown]).not_to be_empty
    end

    it "omits wait_for_less_busy_worker when WEB_CONCURRENCY is 1" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("WEB_CONCURRENCY", 2).and_return("1")

      config = Puma::Configuration.new do |user_config|
        user_config.instance_eval(File.read(puma_config_path), puma_config_path, 1)
      end
      config.load

      expect(config.options[:workers]).to eq(1)
      expect(config.options[:wait_for_less_busy_worker]).to be_nil
    end
  end
end
