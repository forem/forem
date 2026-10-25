require "rails_helper"
require "puma/configuration"

RSpec.describe ServerWarmup, type: :lib do
  after do
    described_class.stop_preboot_keepalive!
    described_class.mark_traffic_received!
  end

  describe ".warmup_enabled?" do
    it "returns false by default in the test environment" do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("PUMA_WARMUP_ENABLED").and_return(false)

      expect(described_class.warmup_enabled?).to be(false)
    end

    it "returns true when PUMA_WARMUP_ENABLED is set to 'true'" do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("PUMA_WARMUP_ENABLED").and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PUMA_WARMUP_ENABLED").and_return("true")

      expect(described_class.warmup_enabled?).to be(true)
    end

    it "returns false when PUMA_WARMUP_ENABLED is set to 'false'" do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("PUMA_WARMUP_ENABLED").and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PUMA_WARMUP_ENABLED").and_return("false")

      expect(described_class.warmup_enabled?).to be(false)
    end

    it "returns true in non-test environments when PUMA_WARMUP_ENABLED is unset" do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("PUMA_WARMUP_ENABLED").and_return(false)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

      expect(described_class.warmup_enabled?).to be(true)
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

    it "continues preloading remaining models when an individual model raises an error" do
      failing_model = Class.new(ApplicationRecord) do
        self.table_name = "users"

        def self.load_schema
          raise ActiveRecord::StatementInvalid, "simulated schema error"
        end
      end

      allow(described_class).to receive(:models_to_preload).and_return([failing_model, Article])

      expect { described_class.preload_model_schemas! }.not_to raise_error
      expect(Article.__send__(:schema_loaded?)).to be(true)
    end
  end

  describe ".warm_database_connections!" do
    before do
      described_class.instance_variable_set(:@traffic_received, false)
    end

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

    it "checks back in already checked-out connections if a subsequent checkout fails" do
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

      expect(described_class.warm_database_connections!(2)).to eq(0)
      expect(mock_pool).to have_received(:checkin).with(mock_conn1).once
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
      described_class.warm_in_memory_caches!

      memory_store = MemoryFirstCache.__send__(:memory_store)
      expect(memory_store.read("memory_first:enabled_global_feature_flags")).to include("community_favorites")
      expect(memory_store.read("memory_first:subforem_default_id")).to be_present
      expect(memory_store.read("memory_first:subforem_root_id")).to be_present
      expect(memory_store.read("memory_first:subforem_domains")).to include("dev.local")
      expect(memory_store.read("memory_first:subforem_all_domains")).to include("dev.local")
      expect(memory_store.read("memory_first:subforem_id_by_domain_dev.local")).to be_present
      expect(RequestStore.store).to be_empty
    end
  end

  describe ".before_fork" do
    it "runs schema preload, warms caches, and always disconnects parent connections in ensure" do
      allow(described_class).to receive(:warmup_enabled?).and_return(true)
      allow(described_class).to receive(:preload_model_schemas!)
      allow(described_class).to receive(:warm_in_memory_caches!).and_raise(StandardError, "simulated error")
      allow(described_class).to receive(:disconnect_parent_connections!)

      expect { described_class.before_fork }.not_to raise_error
      expect(described_class).to have_received(:preload_model_schemas!).once
      expect(described_class).to have_received(:disconnect_parent_connections!).once
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

  describe ".start_preboot_keepalive! and .stop_preboot_keepalive!" do
    it "periodically refreshes connections and Flipper cache until stopped or traffic arrives" do
      described_class.instance_variable_set(:@traffic_received, false)
      refresh_count = 0
      allow(described_class).to receive(:warm_database_connections!) { refresh_count += 1 }
      allow(described_class).to receive(:warm_flipper_cache!)

      described_class.start_preboot_keepalive!(duration_seconds: 2, interval_seconds: 0.02)
      sleep 0.06
      described_class.stop_preboot_keepalive!

      expect(refresh_count).to be >= 1
      expect(described_class).to have_received(:warm_flipper_cache!).at_least(:once)
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
