require "rails_helper"
require Rails.root.join("lib/betterstack/log_device")

RSpec.describe Betterstack::LogDevice do
  # Nothing listens on this port, so nothing is delivered
  let(:unreachable_options) do
    { ingesting_host: "127.0.0.1", ingesting_port: 9, ingesting_scheme: "http", flush_continuously: false }
  end

  it "overrides methods logtail still defines" do
    expect(Logtail::LogDevices::HTTP.private_instance_methods(false))
      .to include(:build_http, :wait_on_request_queue)
  end

  it "verifies Better Stack's TLS certificate" do
    http = described_class.new("token", ingesting_host: "in.logs.example.com").__send__(:build_http)

    expect(http.use_ssl?).to be(true)
    expect(http.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
  end

  it "uses logtail's default host when none is given" do
    http = described_class.new("token", ingesting_host: nil).__send__(:build_http)

    expect(http.address).to eq(Logtail::LogDevices::HTTP::DEFAULT_INGESTING_HOST)
  end

  it "waits between connection attempts" do
    device = described_class.new("token", unreachable_options)
    allow(device).to receive(:sleep)

    device.__send__(:build_http)
    expect(device).not_to have_received(:sleep)

    device.__send__(:build_http)
    expect(device).to have_received(:sleep).with(a_value_within(0.1).of(described_class::RECONNECT_INTERVAL))
  end

  it "stops waiting for undelivered logs after FLUSH_TIMEOUT" do
    stub_const("#{described_class}::FLUSH_TIMEOUT", 0.2)
    device = described_class.new("token", unreachable_options)
    device.write(Logtail::LogEntry.new(:error, Time.current, nil, "boom", {}, nil))

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    device.flush

    expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 1
  end
end
