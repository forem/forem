require 'unit_spec_helper'

describe Rpush::Daemon::Store::ActiveRecord do
  it_behaves_like 'Rpush::Daemon::Store'

  let(:app) { Rpush::Client::ActiveRecord::Apns::App.create!(name: 'my_app', environment: 'development', certificate: TEST_CERT) }
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.create!(device_token: "a" * 64, app: app) }
  let(:store) { Rpush::Daemon::Store::ActiveRecord.new }
  let(:time) { Time.now.utc }
  let(:logger) { double(Rpush::Logger, error: nil, internal_logger: nil) }

  before do
    allow(Rpush).to receive_messages(logger: logger)
    allow(Time).to receive_messages(now: time)
  end

  it 'can release a connection' do
    expect(ActiveRecord::Base.connection).to receive(:close)
    store.release_connection
  end

  it 'logs errors raised when trying to release the connection' do
    e = StandardError.new
    allow(ActiveRecord::Base.connection).to receive(:close).and_raise(e)
    expect(Rpush.logger).to receive(:error).with(e)
    store.release_connection
  end

  describe 'deliverable_notifications' do
    it 'checks for new notifications with the ability to reconnect the database' do
      expect(store).to receive(:with_database_reconnect_and_retry)
      store.deliverable_notifications(Rpush.config.batch_size)
    end

    it 'loads notifications in batches' do
      Rpush.config.batch_size = 5000
      relation = double.as_null_object
      expect(relation).to receive(:limit).with(5000)
      allow(relation).to receive_messages(pluck: [])
      allow(store).to receive_messages(ready_for_delivery: relation)
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
      notification.update!(delivered: false, deliver_after: 1.hour.from_now)
      expect(store.deliverable_notifications(Rpush.config.batch_size)).to be_empty
    end

    it 'does not load a previously delivered notification' do
      notification.update!(delivered: true, delivered_at: time)
      expect(store.deliverable_notifications(Rpush.config.batch_size)).to be_empty
    end

    it "does not enqueue a notification that has previously failed delivery" do
      notification.update!(delivered: false, failed: true)
      expect(store.deliverable_notifications(Rpush.config.batch_size)).to be_empty
    end
  end

  describe "#adapter_name" do
    it "should return the adapter name" do
      adapter = ENV["ADAPTER"] || "postgresql"
      expect(store.adapter_name).to eq(adapter)
    end
  end
end if active_record?
