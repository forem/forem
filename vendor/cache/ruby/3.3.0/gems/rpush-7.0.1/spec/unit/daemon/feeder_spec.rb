require "unit_spec_helper"

describe Rpush::Daemon::Feeder do
  let!(:app) { Rpush::Apns::App.create!(name: 'my_app', environment: 'development', certificate: TEST_CERT) }
  let(:notification) { Rpush::Apns::Notification.create!(device_token: "a" * 108, app: app) }
  let(:logger) { double }
  let(:interruptible_sleeper) { double(sleep: nil, stop: nil) }
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord, deliverable_notifications: [notification], release_connection: nil) }

  before do
    Rpush.configure do |config|
      config.batch_size = 5000
      config.push_poll = 0
      config.push = false
    end

    allow(Rpush).to receive_messages(logger: logger)
    allow(Rpush::Daemon).to receive_messages(store: store)
    allow(Rpush::Daemon::Feeder).to receive_messages(should_stop: true, interruptible_sleeper: interruptible_sleeper)
    allow(Rpush::Daemon::AppRunner).to receive_messages(enqueue: nil, num_queued: 0)
  end

  def start_and_stop
    Rpush::Daemon::Feeder.start
    Rpush::Daemon::Feeder.stop
  end

  it 'loads deliverable notifications' do
    expect(Rpush::Daemon.store).to receive(:deliverable_notifications).with(Rpush.config.batch_size)
    start_and_stop
  end

  it 'does not load more notifications if the total queue size is equal to the batch size' do
    allow(Rpush::Daemon::AppRunner).to receive_messages(total_queued: Rpush.config.batch_size)
    expect(Rpush::Daemon.store).not_to receive(:deliverable_notifications)
    start_and_stop
  end

  it 'limits the batch size if some runners are still processing notifications' do
    allow(Rpush.config).to receive_messages(batch_size: 10)
    allow(Rpush::Daemon::AppRunner).to receive_messages(total_queued: 6)
    expect(Rpush::Daemon.store).to receive(:deliverable_notifications).with(4)
    start_and_stop
  end

  it 'enqueues notifications without looping if in push mode' do
    expect(Rpush::Daemon::Feeder).not_to receive(:feed_forever)
    expect(Rpush::Daemon::Feeder).to receive(:feed_all)
    Rpush::Daemon::Feeder.start(true)
  end

  it "enqueues the notifications" do
    expect(Rpush::Daemon::AppRunner).to receive(:enqueue).with([notification])
    start_and_stop
  end

  it "logs errors" do
    e = StandardError.new("bork")
    allow(Rpush::Daemon.store).to receive(:deliverable_notifications).and_raise(e)
    expect(Rpush.logger).to receive(:error).with(e)
    start_and_stop
  end

  describe 'stop' do
    it 'interrupts sleep' do
      expect(interruptible_sleeper).to receive(:stop)
      start_and_stop
    end

    it 'releases the store connection' do
      expect(Rpush::Daemon.store).to receive(:release_connection)
      start_and_stop
    end
  end

  it 'enqueues notifications when started' do
    expect(Rpush::Daemon::Feeder).to receive(:enqueue_notifications).at_least(:once)
    allow(Rpush::Daemon::Feeder).to receive(:loop).and_yield
    start_and_stop
  end

  it 'sleeps' do
    expect(interruptible_sleeper).to receive(:sleep)
    start_and_stop
  end

  describe 'wakeup' do
    it 'interrupts sleep' do
      expect(interruptible_sleeper).to receive(:stop)
      Rpush::Daemon::Feeder.start
      Rpush::Daemon::Feeder.wakeup
    end

    after { Rpush::Daemon::Feeder.stop }
  end
end
