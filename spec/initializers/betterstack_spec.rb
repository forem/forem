require "rails_helper"
require Rails.root.join("lib/betterstack/log_device")

RSpec.describe "Better Stack initializer" do # rubocop:disable RSpec/DescribeClass
  let(:initializer_path) { Rails.root.join("config/initializers/betterstack.rb") }
  let(:stdout) { StringIO.new }
  let(:stdout_logger) { ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(stdout)) }
  let(:rails_logger) { ActiveSupport::BroadcastLogger.new(stdout_logger).tap { |logger| logger.level = :error } }
  let(:device) { Betterstack::LogDevice.new("token", flush_continuously: false) }

  before do
    allow(Rails).to receive(:logger).and_return(rails_logger)
    allow(Rails.env).to receive(:production?).and_return(true)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BETTERSTACK_SOURCE_TOKEN").and_return("token")
    allow(ENV).to receive(:[]).with("BETTERSTACK_INGESTING_HOST").and_return("in.logs.example.com")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BETTERSTACK_SOURCE_TOKEN").and_return("token")
    allow(Betterstack::LogDevice).to receive(:new).and_return(device)
    allow(device).to receive(:write).and_return(true)
  end

  it "adds a Better Stack logger at the Rails log level" do
    load initializer_path

    betterstack_logger = rails_logger.broadcasts.last
    expect(rails_logger.broadcasts.first).to be(stdout_logger)
    expect(betterstack_logger).to be_a(Logtail::Logger)
    expect(betterstack_logger.level).to eq(Logger::ERROR)
    expect(Betterstack::LogDevice).to have_received(:new).with("token", ingesting_host: "in.logs.example.com")
  end

  it "sends lines at or above the Rails log level to Better Stack and stdout" do
    load initializer_path

    rails_logger.warn("ignored")
    rails_logger.error("boom")

    expect(device).to have_received(:write).once.with(having_attributes(level: :error, message: "boom"))
    expect(stdout.string).to include("boom")
    expect(stdout.string).not_to include("ignored")
  end

  it "runs tagged blocks, like ActiveJob#perform_now, once" do
    load initializer_path
    runs = 0

    rails_logger.tagged("ActiveJob") do
      runs += 1
      rails_logger.error("inside a job")
    end

    expect(runs).to eq(1)
    expect(device).to have_received(:write).once
    expect(stdout.string).to include("[ActiveJob] inside a job")
  end

  it "falls back to logtail's default host when BETTERSTACK_INGESTING_HOST is unset" do
    allow(ENV).to receive(:[]).with("BETTERSTACK_INGESTING_HOST").and_return(nil)

    load initializer_path

    expect(Betterstack::LogDevice).to have_received(:new).with("token", ingesting_host: nil)
  end

  it "does nothing without BETTERSTACK_SOURCE_TOKEN" do
    allow(ENV).to receive(:[]).with("BETTERSTACK_SOURCE_TOKEN").and_return(nil)

    load initializer_path

    expect(rails_logger.broadcasts).to eq([stdout_logger])
  end

  it "does nothing outside production" do
    allow(Rails.env).to receive(:production?).and_return(false)

    load initializer_path

    expect(rails_logger.broadcasts).to eq([stdout_logger])
  end
end
