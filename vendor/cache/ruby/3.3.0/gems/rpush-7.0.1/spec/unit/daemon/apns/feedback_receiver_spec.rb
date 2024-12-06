require 'unit_spec_helper'
require 'rpush/daemon/store/active_record'

describe Rpush::Daemon::Apns::FeedbackReceiver, 'check_for_feedback' do
  let(:host) { 'feedback.push.apple.com' }
  let(:port) { 2196 }
  let(:frequency) { 60 }
  let(:certificate) { double }
  let(:password) { double }
  let(:feedback_enabled) { true }
  let(:app) do
    double(
      name: 'my_app',
      password: password,
      certificate: certificate,
      feedback_enabled: feedback_enabled,
      environment: 'production'
    )
  end
  let(:connection) { double(connect: nil, read: nil, close: nil) }
  let(:logger) { double(error: nil, info: nil) }
  let(:receiver) { Rpush::Daemon::Apns::FeedbackReceiver.new(app) }
  let(:feedback) { double }
  let(:sleeper) { double(Rpush::Daemon::InterruptibleSleep, sleep: nil, stop: nil) }
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord, create_apns_feedback: feedback, release_connection: nil) }

  before do
    Rpush.config.apns.feedback_receiver.frequency = frequency
    allow(Rpush::Daemon::InterruptibleSleep).to receive_messages(new: sleeper)
    allow(Rpush).to receive_messages(logger: logger)
    allow(Rpush::Daemon::TcpConnection).to receive_messages(new: connection)
    receiver.instance_variable_set("@stop", false)
    allow(Rpush::Daemon).to receive_messages(store: store)
  end

  def double_connection_read_with_tuple
    def connection.read(*)
      unless @called
        @called = true
        "N\xE3\x84\r\x00 \x83OxfU\xEB\x9F\x84aJ\x05\xAD}\x00\xAF1\xE5\xCF\xE9:\xC3\xEA\a\x8F\x1D\xA4M*N\xB0\xCE\x17"
      end
    end
  end

  it 'initializes the sleeper with the feedback polling frequency' do
    expect(Rpush::Daemon::InterruptibleSleep).to receive_messages(new: sleeper)
    Rpush::Daemon::Apns::FeedbackReceiver.new(app)
  end

  it 'instantiates a new connection' do
    expect(Rpush::Daemon::TcpConnection).to receive(:new).with(app, host, port)
    receiver.check_for_feedback
  end

  it 'connects to the feeback service' do
    expect(connection).to receive(:connect)
    receiver.check_for_feedback
  end

  it 'closes the connection' do
    expect(connection).to receive(:close)
    receiver.check_for_feedback
  end

  it 'reads from the connection' do
    expect(connection).to receive(:read).with(38)
    receiver.check_for_feedback
  end

  it 'logs the feedback' do
    double_connection_read_with_tuple
    expect(Rpush.logger).to receive(:info).with("[my_app] [FeedbackReceiver] Delivery failed at 2011-12-10 16:08:45 UTC for 834f786655eb9f84614a05ad7d00af31e5cfe93ac3ea078f1da44d2a4eb0ce17.")
    receiver.check_for_feedback
  end

  it 'creates the feedback' do
    expect(Rpush::Daemon.store).to receive(:create_apns_feedback).with(Time.at(1_323_533_325), '834f786655eb9f84614a05ad7d00af31e5cfe93ac3ea078f1da44d2a4eb0ce17', app)
    double_connection_read_with_tuple
    receiver.check_for_feedback
  end

  it 'logs errors' do
    error = StandardError.new('bork!')
    allow(connection).to receive(:read).and_raise(error)
    expect(Rpush.logger).to receive(:error).with(error)
    receiver.check_for_feedback
  end

  describe 'start' do
    before do
      allow(Thread).to receive(:new).and_yield
      allow(receiver).to receive(:loop).and_yield
    end

    it 'sleeps' do
      allow(receiver).to receive(:check_for_feedback)
      expect(sleeper).to receive(:sleep).at_least(:once)
      receiver.start
    end

    it 'checks for feedback when started' do
      expect(receiver).to receive(:check_for_feedback).at_least(:once)
      receiver.start
    end

    context 'with feedback_enabled false' do
      let(:feedback_enabled) { false }

      it 'does not check for feedback when started' do
        expect(receiver).not_to receive(:check_for_feedback)
        receiver.start
      end
    end
  end

  describe 'stop' do
    it 'interrupts sleep when stopped' do
      allow(receiver).to receive(:check_for_feedback)
      expect(sleeper).to receive(:stop)
      receiver.stop
    end

    it 'releases the store connection' do
      allow(Thread).to receive(:new).and_yield
      allow(receiver).to receive(:loop).and_yield
      expect(Rpush::Daemon.store).to receive(:release_connection)
      receiver.start
      receiver.stop
    end
  end

  it 'reflects feedback was received' do
    double_connection_read_with_tuple
    expect(receiver).to receive(:reflect).with(:apns_feedback, feedback)
    receiver.check_for_feedback
  end
end
