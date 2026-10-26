require "rails_helper"

RSpec.describe "Datadog and metrics initializer" do # rubocop:disable RSpec/DescribeClass
  let(:initializer_path) { Rails.root.join("config/initializers/datadog.rb") }

  before do
    stub_const("ForemStatsClient", ForemStatsClient)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
  end

  def load_initializer
    original_verbose = $VERBOSE
    $VERBOSE = nil
    load initializer_path
  ensure
    $VERBOSE = original_verbose
  end

  context "when DD_API_KEY is unset" do
    before do
      allow(ENV).to receive(:[]).with("DD_API_KEY").and_return(nil)
      allow(ENV).to receive(:[]).with("BETTERSTACK_METRICS_SOURCE_TOKEN").and_return(nil)
    end

    it "does not configure Datadog or instantiate Datadog::Statsd, and provides a no-op ForemStatsClient" do
      allow(Kernel).to receive(:require).and_call_original

      load_initializer

      expect(Kernel).not_to have_received(:require).with("ddtrace")
      expect(Kernel).not_to have_received(:require).with("datadog/statsd")
      expect(ForemStatsClient).to be_a(Betterstack::StatsClient)
      expect do
        ForemStatsClient.increment("test.stat", tags: ["env:test"])
        ForemStatsClient.count("test.count", 2, tags: ["env:test"])
        ForemStatsClient.gauge("test.gauge", 10, tags: ["env:test"])
        ForemStatsClient.event("title", "text", tags: ["env:test"])
      end.not_to raise_error
    end

    it "sends metrics to Better Stack in production when BETTERSTACK_METRICS_SOURCE_TOKEN is set" do
      require Rails.root.join("lib/betterstack/log_device")
      device = Betterstack::LogDevice.new("bs-metrics-token", flush_continuously: false)
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(ENV).to receive(:[]).with("BETTERSTACK_METRICS_SOURCE_TOKEN").and_return("bs-metrics-token")
      allow(ENV).to receive(:[]).with("BETTERSTACK_METRICS_INGESTING_HOST").and_return("in.metrics.example.com")
      allow(Betterstack::LogDevice).to receive(:new).and_return(device)
      allow(device).to receive(:write).and_return(true)

      load_initializer

      expect(Betterstack::LogDevice).to have_received(:new).with(
        "bs-metrics-token",
        ingesting_host: "in.metrics.example.com",
      )
      ForemStatsClient.increment("test.stat", tags: ["env:production"])
      expect(device).to have_received(:write).once
    end
  end

  context "when DD_API_KEY is present" do
    before do
      require "ddtrace"
      require "datadog/statsd"
      allow(ENV).to receive(:[]).with("DD_API_KEY").and_return("dd-api-key")
      allow(ENV).to receive(:[]).with("BETTERSTACK_METRICS_SOURCE_TOKEN").and_return(nil)
    end

    it "configures Datadog tracing and forwards ForemStatsClient calls to Datadog::Statsd" do
      statsd = instance_double(Datadog::Statsd, increment: nil, count: nil, gauge: nil, event: nil)
      allow(Datadog).to receive(:configure)
      allow(Datadog::Statsd).to receive(:new).and_return(statsd)

      load_initializer

      expect(Datadog).to have_received(:configure)
      ForemStatsClient.increment("test.stat", tags: ["env:test"])
      expect(statsd).to have_received(:increment).with("test.stat", { tags: ["env:test"] })
    end
  end
end
