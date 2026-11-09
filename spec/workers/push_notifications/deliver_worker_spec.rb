require "rails_helper"

RSpec.describe PushNotifications::DeliverWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    before { allow(Rpush).to receive(:push) }

    it "delivers pending push notifications" do
      worker.perform

      expect(Rpush).to have_received(:push).once
    end

    # Rpush 9 removed the legacy APNs binary protocol along with
    # Rpush.apns_feedback, so calling it raised NoMethodError after every push.
    it "does not raise after delivering" do
      expect { worker.perform }.not_to raise_error
    end
  end

  describe "Rpush APNs HTTP/2 transient transport error handling" do
    it "marks the batch retryable and closes the HTTP/2 client on Errno::EPIPE (Broken pipe)" do
      app = instance_double(Rpush::Apns2::App, bundle_id: "com.forem.app")
      client = instance_double(NetHttp2::Client, close: nil)
      batch = instance_double(Rpush::Daemon::Batch, each_notification: nil, all_processed: nil)
      allow(client).to receive(:join).and_raise(Errno::EPIPE, "Broken pipe")

      delivery = Rpush::Daemon::Apns2::Delivery.new(app, client, batch)
      allow(delivery).to receive(:mark_batch_retryable)
      allow(delivery).to receive(:mark_batch_failed)

      expect { delivery.perform }.to raise_error(Errno::EPIPE)
      expect(delivery).to have_received(:mark_batch_retryable).with(kind_of(Time), instance_of(Errno::EPIPE))
      expect(delivery).not_to have_received(:mark_batch_failed)
      expect(client).to have_received(:close)
      expect(batch).to have_received(:all_processed)
    end

    it "logs a warning instead of calling Rails.error.report for transient socket notification_failed callbacks" do
      allow(Rails.error).to receive(:report)
      allow(Rails.logger).to receive(:warn)
      allow(ForemStatsClient).to receive(:increment)

      notification = Rpush::Apns2::Notification.new(
        error_code: nil,
        error_description: "undefined method 'write' for nil",
      )

      Rpush.reflection_stack[0].__dispatch(:notification_failed, notification)

      expect(Rails.error).not_to have_received(:report)
      expect(Rails.logger).to have_received(:warn).with(include("Transient transport failure"))
    end
  end
end
