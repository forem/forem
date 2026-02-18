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
end
