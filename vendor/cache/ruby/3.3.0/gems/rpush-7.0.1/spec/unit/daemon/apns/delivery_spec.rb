require 'unit_spec_helper'

describe Rpush::Daemon::Apns::Delivery do
  let(:app) { double(name: 'MyApp') }
  let(:notification1) { double.as_null_object }
  let(:notification2) { double.as_null_object }
  let(:batch) { double(mark_all_failed: nil, mark_all_delivered: nil, all_processed: nil) }
  let(:logger) { double(error: nil, info: nil) }
  let(:connection) { double(select: false, write: nil, reconnect: nil, close: nil, connect: nil) }
  let(:delivery) { Rpush::Daemon::Apns::Delivery.new(app, connection, batch) }

  before do
    allow(batch).to receive(:each_notification) do |&blk|
      [notification1, notification2].each(&blk)
    end
    allow(Rpush).to receive_messages(logger: logger)
  end

  it 'writes the binary batch' do
    allow(notification1).to receive_messages(to_binary: 'binary1')
    allow(notification2).to receive_messages(to_binary: 'binary2')
    expect(connection).to receive(:write).with('binary1binary2')
    delivery.perform
  end

  it 'logs the notification deliveries' do
    allow(notification1).to receive_messages(id: 666, device_token: 'abc123')
    allow(notification2).to receive_messages(id: 42, device_token: 'abc456')
    expect(logger).to receive(:info).with('[MyApp] 666 sent to abc123')
    expect(logger).to receive(:info).with('[MyApp] 42 sent to abc456')
    delivery.perform
  end

  it 'marks all notifications as delivered' do
    expect(delivery).to receive(:mark_batch_delivered)
    delivery.perform
  end

  it 'notifies the batch all notifications have been processed' do
    expect(batch).to receive(:all_processed)
    delivery.perform
  end

  describe 'when an error is raised' do
    it 'marks all notifications as failed' do
      error = StandardError.new
      allow(connection).to receive(:write).and_raise(error)
      expect(delivery).to receive(:mark_batch_failed).with(error)
      expect { delivery.perform }.to raise_error(error)
    end
  end

  # describe "when delivery fails" do
  #   before { connection.stub(select: true, read: [8, 4, 69].pack("ccN")) }
  #
  #   it "marks the notification as failed" do
  #     delivery.should_receive(:mark_failed).with(4, "Unable to deliver notification 69, received error 4 (Missing payload)")
  #     perform
  #   end
  #
  #   it "logs the delivery error" do
  #     # checking for the doublebed error doesn't work in jruby, but checking
  #     # for the exception by class does.
  #
  #     # error = Rpush::DeliveryError.new(4, 12, "Missing payload")
  #     # Rpush::DeliveryError.stub(new: error)
  #     # expect { delivery.perform }.to raise_error(error)
  #
  #     expect { delivery.perform }.to raise_error(Rpush::DeliveryError)
  #   end
  #
  #   it "reads 6 bytes from the socket" do
  #     connection.should_receive(:read).with(6).and_return(nil)
  #     perform
  #   end
  #
  #   it "does not attempt to read from the socket if the socket was not selected for reading after the timeout" do
  #     connection.stub(select: nil)
  #     connection.should_not_receive(:read)
  #     perform
  #   end
  #
  #   it "reconnects the socket" do
  #     connection.should_receive(:reconnect)
  #     perform
  #   end
  #
  #   it "logs that the connection is being reconnected" do
  #     Rpush.logger.should_receive(:error).with("[MyApp] Error received, reconnecting...")
  #     perform
  #   end
  #
  #   context "when the APNs disconnects without returning an error" do
  #     before do
  #       connection.stub(read: nil)
  #     end
  #
  #     it 'raises a DisconnectError error if the connection is closed without an error being returned' do
  #       expect { delivery.perform }.to raise_error(Rpush::DisconnectionError)
  #     end
  #
  #     it 'marks the notification as failed' do
  #       delivery.should_receive(:mark_failed).with(nil, "The APNs disconnected without returning an error. This may indicate you are using an invalid certificate for the host.")
  #       perform
  #     end
  #   end
  # end
end
