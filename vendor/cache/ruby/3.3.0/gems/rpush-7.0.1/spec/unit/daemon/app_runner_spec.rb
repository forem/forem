require 'unit_spec_helper'
require 'rpush/daemon/store/active_record'

module Rpush
  module AppRunnerSpecService
    class App < Rpush::App
    end
  end

  module Daemon
    module AppRunnerSpecService
      extend ServiceConfigMethods

      class ServiceLoop
        def initialize(*)
        end

        def start
        end

        def stop
        end
      end

      dispatcher :http
      loops ServiceLoop

      class Delivery
      end
    end
  end
end

describe Rpush::Daemon::AppRunner, 'enqueue' do
  let(:app) { double(id: 1, name: 'Test', connections: 1) }
  let(:notification) { double(app_id: 1) }
  let(:runner) { double(Rpush::Daemon::AppRunner, enqueue: nil, start_dispatchers: nil, start_loops: nil, stop: nil) }
  let(:logger) { double(Rpush::Logger, error: nil, info: nil) }

  before do
    allow(Rpush).to receive_messages(logger: logger)
    allow(Rpush::Daemon::ProcTitle).to receive(:update)
    allow(Rpush::Daemon::AppRunner).to receive_messages(new: runner)
    Rpush::Daemon::AppRunner.start_app(app)
  end

  after { Rpush::Daemon::AppRunner.stop }

  it 'enqueues notifications on the runner' do
    expect(runner).to receive(:enqueue).with([notification])
    Rpush::Daemon::AppRunner.enqueue([notification])
  end

  it 'starts the app if a runner does not exist' do
    notification = double(app_id: 3)
    new_app = double(Rpush::App, id: 3, name: 'NewApp', connections: 1)
    Rpush::Daemon.store = double(app: new_app)
    Rpush::Daemon::AppRunner.enqueue([notification])
    expect(Rpush::Daemon::AppRunner.app_running?(new_app)).to eq(true)
  end
end

describe Rpush::Daemon::AppRunner, 'start_app' do
  let(:app) { double(id: 1, name: 'test', connections: 1) }
  let(:runner) { double(Rpush::Daemon::AppRunner, enqueue: nil, start_dispatchers: nil, stop: nil) }
  let(:logger) { double(Rpush::Logger, error: nil, info: nil) }

  before do
    allow(Rpush).to receive_messages(logger: logger)
  end

  it 'logs an error if the runner could not be started' do
    expect(Rpush::Daemon::AppRunner).to receive(:new).with(app).and_return(runner)
    allow(runner).to receive(:start_dispatchers).and_raise(StandardError)
    expect(Rpush.logger).to receive(:error)
    Rpush::Daemon::AppRunner.start_app(app)
  end
end

describe Rpush::Daemon::AppRunner, 'debug' do
  let(:app) do
    double(Rpush::AppRunnerSpecService::App, id: 1, name: 'test', connections: 1,
                                             environment: 'development', certificate: TEST_CERT,
                                             service_name: 'app_runner_spec_service')
  end
  let(:logger) { double(Rpush::Logger, info: nil) }
  let(:store) { double(all_apps: [app], release_connection: nil) }

  before do
    allow(Rpush::Daemon).to receive_messages(config: {}, store: store)
    allow(Rpush).to receive_messages(logger: logger)
    Rpush::Daemon::AppRunner.start_app(app)
  end

  after { Rpush::Daemon::AppRunner.stop_app(app.id) }

  it 'returns the app runner status' do
    expect(Rpush::Daemon::AppRunner.status.key?(:app_runners)).to eq(true)
  end
end

describe Rpush::Daemon::AppRunner do
  let(:app) do
    double(Rpush::AppRunnerSpecService::App, environment: :sandbox,
                                             connections: 1, service_name: 'app_runner_spec_service',
                                             name: 'test')
  end
  let(:runner) { Rpush::Daemon::AppRunner.new(app) }
  let(:logger) { double(Rpush::Logger, info: nil) }
  let(:queue) { Queue.new }
  let(:service_loop) { double(Rpush::Daemon::AppRunnerSpecService::ServiceLoop, start: nil, stop: nil) }
  let(:dispatcher_loop) { double(Rpush::Daemon::DispatcherLoop, stop: nil, start: nil) }
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord, release_connection: nil) }

  before do
    allow(Rpush::Daemon::DispatcherLoop).to receive_messages(new: dispatcher_loop)
    allow(Rpush::Daemon).to receive_messages(store: store)
    allow(Rpush::Daemon::AppRunnerSpecService::ServiceLoop).to receive_messages(new: service_loop)
    allow(Queue).to receive_messages(new: queue)
    allow(Rpush).to receive_messages(logger: logger)
  end

  describe 'start' do
    it 'starts a delivery dispatcher for each connection' do
      allow(app).to receive_messages(connections: 2)
      runner.start_dispatchers
      expect(runner.num_dispatcher_loops).to eq 2
    end

    it 'starts the dispatcher loop' do
      expect(dispatcher_loop).to receive(:start)
      runner.start_dispatchers
    end

    it 'starts the loops' do
      expect(service_loop).to receive(:start)
      runner.start_loops
    end
  end

  describe 'enqueue' do
    let(:notification) { double }

    it 'enqueues the batch' do
      expect(queue).to receive(:push) do |queue_payload|
        expect(queue_payload.notification).to eq notification
        expect(queue_payload.batch).not_to be_nil
      end
      runner.enqueue([notification])
    end

    it 'reflects the notification has been enqueued' do
      expect(runner).to receive(:reflect).with(:notification_enqueued, notification)
      runner.enqueue([notification])
    end

    describe 'a service that batches deliveries' do
      before do
        allow(runner.send(:service)).to receive_messages(batch_deliveries?: true)
      end

      describe '1 notification with more than one dispatcher loop' do
        it 'does not raise ArgumentError: invalid slice size' do
          # https://github.com/rpush/rpush/issues/57
          allow(runner).to receive(:num_dispatcher_loops).and_return(2)
          runner.enqueue([notification])
        end
      end
    end
  end

  describe 'stop' do
    before do
      runner.start_dispatchers
      runner.start_loops
    end

    it 'stops the delivery dispatchers' do
      expect(dispatcher_loop).to receive(:stop)
      runner.stop
    end

    it 'stop the loops' do
      expect(service_loop).to receive(:stop)
      runner.stop
    end
  end
end
