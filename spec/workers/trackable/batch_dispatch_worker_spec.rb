require "rails_helper"

RSpec.describe Trackable::BatchDispatchWorker, type: :worker do
  let(:adapter_class) do
    Class.new(Trackers::Base) do
      def track(event_name:, user_ids:, properties:, timestamp: nil); end
      def track_batch(**); end
    end
  end

  before do
    Trackable::Registry.reset!
    Trackable::Registry.register(:dummy, adapter_class)
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy")
  end

  after { Trackable::Registry.reset! }

  it "hands the event to the named adapter's #track_batch" do
    adapter = Trackable::Registry.instance_for(:dummy)
    allow(adapter).to receive(:track_batch)

    described_class.new.perform("dummy", "notifications_sent", { "kind" => "comment" }, "dev:notifications", [1, 2],
                                "2026-11-20T14:02:11.482Z", { "notification_ids" => [8, 9] })

    expect(adapter).to have_received(:track_batch).with(
      event_name: "notifications_sent",
      properties: { "kind" => "comment" },
      anonymous_id: "dev:notifications",
      recipient_ids: [1, 2],
      recipient_properties: { "notification_ids" => [8, 9] },
      timestamp: Time.iso8601("2026-11-20T14:02:11.482Z"),
    )
  end

  it "skips an adapter that is disabled" do
    adapter = Trackable::Registry.instance_for(:dummy)
    allow(adapter).to receive_messages(enabled?: false, track_batch: nil)

    described_class.new.perform("dummy", "notifications_sent", {}, "dev:notifications", nil, nil)

    expect(adapter).not_to have_received(:track_batch)
  end

  it "re-raises adapter errors so Sidekiq retries" do
    adapter = Trackable::Registry.instance_for(:dummy)
    allow(adapter).to receive(:track_batch).and_raise(StandardError, "boom")

    expect do
      described_class.new.perform("dummy", "notifications_sent", {}, "dev:notifications", nil, nil)
    end.to raise_error(StandardError, "boom")
  end

  describe Trackable::BatchEvent do
    it "enqueues one job per active adapter with a shared timestamp" do
      sidekiq_assert_enqueued_jobs(1, only: Trackable::BatchDispatchWorker) do
        described_class.enqueue("notifications_read", properties: { "scope" => "all" },
                                                      anonymous_id: "dev:notifications", recipient_ids: ["7"],
                                                      recipient_properties: { "notification_ids" => [70] })
      end

      args = Trackable::BatchDispatchWorker.jobs.last["args"]
      expect(args.first(5)).to eq(["dummy", "notifications_read", { "scope" => "all" }, "dev:notifications", [7]])
      expect { Time.iso8601(args[5]) }.not_to raise_error
      expect(args.last).to eq("notification_ids" => [70])
    end
  end
end
