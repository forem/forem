require 'unit_spec_helper'

describe Rpush::Daemon::Store::Redis do
  it_behaves_like 'Rpush::Daemon::Store'

  let(:app) { Rpush::Client::Redis::Apns::App.create!(name: 'my_app', environment: 'development', certificate: TEST_CERT) }
  let(:notification) { Rpush::Client::Redis::Apns::Notification.create!(device_token: "a" * 64, app: app) }
  let(:store) { Rpush::Daemon::Store::Redis.new }
  let(:time) { Time.now.utc }
  let(:logger) { double(Rpush::Logger, error: nil, internal_logger: nil) }

  before do
    allow(Rpush).to receive_messages(logger: logger)
    allow(Time).to receive_messages(now: time)
  end

  describe 'deliverable_notifications' do
    it 'loads notifications in batches' do
      Rpush.config.batch_size = 100
      allow(store).to receive_messages(pending_notification_ids: [1, 2, 3, 4])
      expect(Rpush::Client::Redis::Notification).to receive(:find).exactly(4).times
      store.deliverable_notifications(Rpush.config.batch_size)
    end

    it 'loads an undelivered notification without deliver_after set' do
      notification.update!(delivered: false, deliver_after: nil)
      expect(store.deliverable_notifications(Rpush.config.batch_size)).to eq [notification]
    end

    it 'loads an notification with a deliver_after time in the past' do
      notification.update!(delivered: false, deliver_after: 1.hour.ago)
      expect(store.deliverable_notifications(Rpush.config.batch_size)).to eq [notification]
    end

    it 'does not load an notification with a deliver_after time in the future' do
      notification
      notification = store.deliverable_notifications(Rpush.config.batch_size).first
      store.mark_retryable(notification, 1.hour.from_now)
      expect(store.deliverable_notifications(Rpush.config.batch_size)).to be_empty
    end

    it 'does not load a previously delivered notification' do
      notification
      notification = store.deliverable_notifications(Rpush.config.batch_size).first
      store.mark_delivered(notification, Time.now)
      expect(store.deliverable_notifications(Rpush.config.batch_size)).to be_empty
    end

    it "does not enqueue a notification that has previously failed delivery" do
      notification
      notification = store.deliverable_notifications(Rpush.config.batch_size).first
      store.mark_failed(notification, 0, "failed", Time.now)
      expect(store.deliverable_notifications(Rpush.config.batch_size)).to be_empty
    end
  end

  describe 'mark_ids_retryable' do
    let(:deliver_after) { time + 10.seconds }

    it 'sets the deliver after timestamp' do
      expect do
        store.mark_ids_retryable([notification.id], deliver_after)
        notification.reload
      end.to change { notification.deliver_after.try(:utc).to_s }.to(deliver_after.utc.to_s)
    end

    it 'ignores IDs that do not exist without throwing an exception' do
      notification.destroy
      expect(logger).to receive(:warn).with("Couldn't find Rpush::Client::Redis::Notification with id=#{notification.id}")
      expect do
        store.mark_ids_retryable([notification.id], deliver_after)
      end.not_to raise_exception
    end
  end

  describe 'mark_ids_failed' do
    it 'marks the notification as failed' do
      expect do
        store.mark_ids_failed([notification.id], nil, '', Time.now)
        notification.reload
      end.to change(notification, :failed).to(true)
    end

    it 'ignores IDs that do not exist without throwing an exception' do
      notification.destroy
      expect(logger).to receive(:warn).with("Couldn't find Rpush::Client::Redis::Notification with id=#{notification.id}")
      expect do
        store.mark_ids_failed([notification.id], nil, '', Time.now)
      end.not_to raise_exception
    end
  end
end if redis?
