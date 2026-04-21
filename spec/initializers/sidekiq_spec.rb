require "rails_helper"

RSpec.describe "Sidekiq Initializer" do
  let(:initializer_path) { Rails.root.join("config/initializers/sidekiq.rb") }

  it "loads the Sidekiq configuration without errors in client context" do
    expect { load initializer_path }.not_to raise_error
  end

  it "defines sidekiq-throttled server middleware constant" do
    require "sidekiq/throttled"
    expect(defined?(Sidekiq::Throttled::Middlewares::Server)).to eq("constant")
  end

  it "loads without errors when Sidekiq is running as a server (production boot scenario)" do
    # In real production Sidekiq boot, `Sidekiq.server?` is true because Sidekiq defines
    # `Sidekiq::CLI` before loading Rails (and therefore before running initializers).
    # This simulates that scenario to ensure the initializer won't crash on production boot.
    stub_const("Sidekiq::CLI", Class.new)

    # The initializer should load without errors even when Sidekiq is in server mode.
    # The gem's configure_server block will run when the gem is required (which happens
    # in the initializer via `require "sidekiq/throttled"`), and our initializer's
    # configure_server block will also run.
    expect { load initializer_path }.not_to raise_error

    # Verify sidekiq-throttled is properly loaded and configured
    expect(defined?(Sidekiq::Throttled::Middlewares::Server)).to eq("constant")
  end

  it "registers a throttle strategy for BatchCustomSendWorker" do
    expect(Emails::BatchCustomSendWorker.included_modules).to include(Sidekiq::Throttled::Job)

    strategy = Sidekiq::Throttled::Registry.get(Emails::BatchCustomSendWorker)
    expect(strategy).to be_a(Sidekiq::Throttled::Strategy)
  end

  describe "Database Pool Decoupling" do
    it "reconnects to the database with SIDEKIQ_CONCURRENCY upon Sidekiq startup" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SIDEKIQ_CONCURRENCY", 16).and_return("25")

      startup_blocks = []
      
      # Since Sidekiq.configure_server blocks only yield when Sidekiq is running as a server,
      # we bypass the internal state check and manually yield a mock to capture the `.on(:startup)` hook.
      allow(Sidekiq).to receive(:configure_server).and_wrap_original do |original_method, &block|
        config_mock = double("SidekiqConfig").as_null_object
        allow(config_mock).to receive(:on) # allow other hooks like :shutdown
        allow(config_mock).to receive(:on).with(:startup) { |&startup| startup_blocks << startup }
        block.call(config_mock)
      end

      load initializer_path

      our_block = startup_blocks.find { |b| b.source_location[0].include?("config/initializers/sidekiq.rb") }
      expect(our_block).not_to be_nil, "Expected config.on(:startup) loop to be defined"

      pool_mock = double("ConnectionPool")
      expect(pool_mock).to receive(:disconnect!)
      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(pool_mock)
      
      expected_db_config = Rails.application.config.database_configuration[Rails.env].merge('pool' => 25)
      expect(ActiveRecord::Base).to receive(:establish_connection).with(expected_db_config)
      
      # Simulate Sidekiq boot completing and triggering our specific startup hook
      our_block.call
    end
  end
end
