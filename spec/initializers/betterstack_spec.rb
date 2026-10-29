require "rails_helper"
require "logtail-rails"
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
    # The app's middleware stack is frozen after boot.
    allow(Rails.application.config.middleware).to receive(:insert_after)
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

  it "sends logtail-rails events only to Better Stack, with the user's id and no other user data" do
    load initializer_path

    expect(Logtail.config.logger).to be(rails_logger.broadcasts.last)
    expect(Logtail::Integrations::ActionController).not_to be_enabled
    expect(Logtail::Integrations::Rails::ErrorEvent).not_to be_enabled
    expect(Rails.application.config.middleware).to have_received(:insert_after)
      .with(ActionDispatch::RequestId, Betterstack::RequestContext)
    user = instance_double(User, id: 7, name: "Ada", email: "ada@example.com")
    env = { "warden" => instance_double(Warden::Proxy, user: user) }
    expect(Logtail::Integrations::Rack::UserContext.custom_user_hash.call(env)).to eq(id: 7)
  end

  it "keeps exceptions Rails rescues into responses out of Better Stack, but on stdout" do
    sent = []
    # Upstream's LogDevice#write applies the filter first; device.write is stubbed above.
    allow(device).to receive(:write) { |entry| sent << entry.message if Logtail.config.send_to_better_stack?(entry) }
    load initializer_path

    rails_logger.error("  \n[req-1] ActiveRecord::RecordNotFound (Not Found):\n  app/x.rb:1")
    rails_logger.error("[req-2] Pundit::NotAuthorizedError (not allowed)")
    rails_logger.error("PG::NotNullViolation (null value)\nCaused by: ActiveRecord::RecordNotFound (x)")

    expect(sent).to eq(["PG::NotNullViolation (null value)\nCaused by: ActiveRecord::RecordNotFound (x)"])
    expect(stdout.string).to include("RecordNotFound", "Pundit::NotAuthorizedError")
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
