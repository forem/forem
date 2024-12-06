require 'unit_spec_helper'

describe Rpush::Daemon::Dispatcher::Tcp do
  let(:app) { double }
  let(:delivery) { double(perform: nil) }
  let(:delivery_class) { double(new: delivery) }
  let(:notification) { double }
  let(:batch) { double }
  let(:connection) { double(Rpush::Daemon::TcpConnection, connect: nil) }
  let(:host) { 'localhost' }
  let(:port) { 1234 }
  let(:host_proc) { proc { [host, port] } }
  let(:queue_payload) { Rpush::Daemon::QueuePayload.new(batch, notification) }
  let(:dispatcher) { Rpush::Daemon::Dispatcher::Tcp.new(app, delivery_class, host: host_proc) }

  before { allow(Rpush::Daemon::TcpConnection).to receive_messages(new: connection) }

  describe 'dispatch' do
    it 'delivers the notification' do
      expect(delivery_class).to receive(:new).with(app, connection, notification, batch).and_return(delivery)
      expect(delivery).to receive(:perform)
      dispatcher.dispatch(queue_payload)
    end
  end

  describe 'cleanup' do
    it 'closes the connection' do
      expect(connection).to receive(:close)
      dispatcher.cleanup
    end
  end
end
