require 'unit_spec_helper'

describe Rpush::Daemon::DispatcherLoop do
  def run_dispatcher_loop
    dispatcher_loop.start
    dispatcher_loop.stop
  end

  let(:notification) { double }
  let(:batch) { double(notification_processed: nil) }
  let(:queue) { Queue.new }
  let(:dispatcher) { double(dispatch: nil, cleanup: nil) }
  let(:dispatcher_loop) { Rpush::Daemon::DispatcherLoop.new(queue, dispatcher) }
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord, release_connection: nil) }

  before do
    allow(Rpush::Daemon).to receive_messages(store: store)
    queue.push([notification, batch])
  end

  it 'logs errors' do
    logger = double
    allow(Rpush).to receive_messages(logger: logger)
    error = StandardError.new
    allow(dispatcher).to receive(:dispatch).and_raise(error)
    expect(Rpush.logger).to receive(:error).with(error)
    run_dispatcher_loop
  end

  it 'reflects an exception' do
    allow(Rpush).to receive_messages(logger: double(error: nil))
    error = StandardError.new
    allow(dispatcher).to receive(:dispatch).and_raise(error)
    expect(dispatcher_loop).to receive(:reflect).with(:error, error)
    run_dispatcher_loop
  end

  describe 'stop' do
    before do
      queue.clear
    end

    it 'instructs the dispatcher to cleanup' do
      expect(dispatcher).to receive(:cleanup)
      run_dispatcher_loop
    end

    it 'releases the store connection' do
      expect(Rpush::Daemon.store).to receive(:release_connection)
      run_dispatcher_loop
    end
  end
end
