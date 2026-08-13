require "rails_helper"

RSpec.describe Trackable::DispatchWorker, type: :worker do
  let(:adapter_class) do
    Class.new(Trackers::Base) do
      def track(event_name:, user_ids:, properties:, timestamp: nil); end
    end
  end

  before { Trackable::Registry.reset! }
  after  { Trackable::Registry.reset! }

  describe "#perform" do
    let(:worker) { described_class.new }

    before do
      Trackable::Registry.register(:dummy, adapter_class)
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy")
    end

    it "calls #track on the named adapter with the provided arguments" do
      adapter = Trackable::Registry.instance_for(:dummy)
      allow(adapter).to receive(:track)

      worker.perform("dummy", "article_created", [1, 2], { "title" => "t" }, nil)

      expect(adapter).to have_received(:track).with(
        event_name: "article_created",
        user_ids: [1, 2],
        properties: { "title" => "t" },
        timestamp: nil,
      )
    end

    it "parses an ISO timestamp string back into a Time" do
      adapter = Trackable::Registry.instance_for(:dummy)
      allow(adapter).to receive(:track)
      iso = "2026-05-01T12:00:00Z"

      worker.perform("dummy", "x", [1], {}, iso)

      expect(adapter).to have_received(:track).with(
        hash_including(timestamp: Time.iso8601(iso)),
      )
    end

    it "no-ops when the adapter is unknown" do
      expect { worker.perform("nope", "x", [1], {}, nil) }.not_to raise_error
    end

    it "no-ops when the adapter is disabled" do
      adapter = Trackable::Registry.instance_for(:dummy)
      allow(adapter).to receive(:enabled?).and_return(false)
      allow(adapter).to receive(:track)

      worker.perform("dummy", "x", [1], {}, nil)

      expect(adapter).not_to have_received(:track)
    end

    it "rescues adapter exceptions and logs them" do
      adapter = Trackable::Registry.instance_for(:dummy)
      allow(adapter).to receive(:track).and_raise(StandardError, "boom")
      allow(Rails.logger).to receive(:error)

      expect { worker.perform("dummy", "x", [1], {}, nil) }.to raise_error(StandardError, "boom")
      expect(Rails.logger).to have_received(:error).with(a_string_including("dummy")).at_least(:once)
    end
  end

  describe ".sidekiq_retries_exhausted" do
    # A dead-lettered event is silent DEV -> Core drift; make it page.
    it "notifies Honeybadger when an event exhausts its retries" do
      allow(Honeybadger).to receive(:notify)
      job = { "args" => ["customerio_cdp", "user_updated", [1], {}, nil], "error_message" => "boom" }

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new("boom"))

      expect(Honeybadger).to have_received(:notify)
    end
  end
end
