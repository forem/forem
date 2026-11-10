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

    it "serializes concurrent perform calls with PUSH_MUTEX so Rpush.push never overlaps" do
      active_count = 0
      max_concurrent = 0
      state_mutex = Mutex.new
      entered = Queue.new
      release = Queue.new

      allow(Rpush).to receive(:push) do
        state_mutex.synchronize do
          active_count += 1
          max_concurrent = [max_concurrent, active_count].max
        end
        entered << true
        release.pop
      ensure
        state_mutex.synchronize { active_count -= 1 }
      end

      t1 = Thread.new { described_class.new.perform }
      entered.pop
      t2 = Thread.new { described_class.new.perform }
      # Give t2 a moment to block on PUSH_MUTEX while t1 holds it
      sleep 0.02
      release << true
      entered.pop
      release << true
      [t1, t2].each(&:join)

      expect(max_concurrent).to eq(1)
      expect(Rpush).to have_received(:push).twice
    end

    it "configures until_and_while_executing lock with client :log and server :reschedule conflict handling" do
      expect(described_class.sidekiq_options_hash).to include(
        "lock" => :until_and_while_executing,
        "lock_ttl" => 120,
        "on_conflict" => { client: :log, server: :reschedule },
      )
    end
  end

  describe "Rpush APNs HTTP/2 transient transport error handling" do
    it "raises a retryable SocketError instead of NoMethodError when NetHttp2::Client @socket is nil" do
      client = NetHttp2::Client.new("https://api.push.apple.com:443")
      client.instance_variable_set(:@socket, nil)
      h2_client = client.__send__(:h2)

      expect { h2_client.emit(:frame, "ping") }.to raise_error(SocketError, "Socket was remotely closed")
    end

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
