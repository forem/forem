require "rails_helper"

RSpec.describe "Honeycomb initializer" do # rubocop:disable RSpec/DescribeClass
  let(:initializer_path) { Rails.root.join("config/initializers/honeycomb.rb") }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(Rails.application.config.middleware).to receive(:insert_after)
  end

  after do
    allow(ApplicationConfig).to receive(:[]).with("HONEYCOMB_API_KEY").and_return(nil)
    load initializer_path
  end

  context "when HONEYCOMB_API_KEY is unset" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("HONEYCOMB_API_KEY").and_return(nil)
    end

    it "does not require honeycomb-beeline or install middleware, and provides no-op Honeycomb methods" do
      allow(Kernel).to receive(:require).and_call_original

      load initializer_path

      expect(Kernel).not_to have_received(:require).with("honeycomb-beeline")
      expect(Rails.application.config.middleware).not_to have_received(:insert_after)
      expect { Honeycomb.add_field("test.key", "val") }.not_to raise_error
      expect(Honeycomb.start_span(name: "test") { "ok" }).to eq("ok")
    end
  end

  context "when HONEYCOMB_API_KEY is present" do
    before do
      require "honeycomb-beeline"
      allow(ApplicationConfig).to receive(:[]).with("HONEYCOMB_API_KEY").and_return("hc-api-key")
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("rel-123")
    end

    it "configures Honeycomb and mounts Honeycomb::Rails::Middleware" do
      config_spy = Honeycomb::Configuration.new
      client_double = instance_double(Honeycomb::Client)
      allow(Honeycomb).to receive(:configure).and_yield(config_spy)
      allow(Honeycomb).to receive(:client).and_return(client_double)

      load initializer_path

      expect(Honeycomb).to have_received(:configure)
      expect(config_spy.write_key).to eq("hc-api-key")
      expect(config_spy.notification_events).to include("sql.active_record", "process_action.action_controller")
      expect(Rails.application.config.middleware).to have_received(:insert_after).with(
        ActionDispatch::ShowExceptions,
        Honeycomb::Rails::Middleware,
        client: client_double,
      )
    end
  end
end
