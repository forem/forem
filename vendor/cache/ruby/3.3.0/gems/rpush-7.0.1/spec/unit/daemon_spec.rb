require 'unit_spec_helper'
require 'rpush/daemon/store/active_record'

describe Rpush::Daemon, "when starting" do
  module Rails; end

  let(:certificate) { double }
  let(:password) { double }
  let(:logger) { double(:logger, info: nil, error: nil, warn: nil, internal_logger: nil) }

  before do
    allow(Rpush).to receive(:logger) { logger }
    allow(Rpush::Daemon::Feeder).to receive(:start)
    allow(Rpush::Daemon::Synchronizer).to receive(:sync)
    allow(Rpush::Daemon::AppRunner).to receive(:stop)
    allow(Rpush::Daemon::Rpc::Server).to receive(:start)
    allow(Rpush::Daemon::Rpc::Server).to receive(:stop)
    allow(Rpush::Daemon).to receive(:exit)
    allow(Rpush::Daemon).to receive(:puts)
    allow(Rpush::Daemon::SignalHandler).to receive(:start)
    allow(Rpush::Daemon::SignalHandler).to receive(:stop)
    allow(Rpush::Daemon::SignalHandler).to receive(:handle_shutdown_signal)
    allow(Process).to receive(:daemon)
    allow(File).to receive(:open)
  end

  unless Rpush.jruby?
    it "forks into a daemon if the foreground option is false" do
      Rpush.config.foreground = false
      Rpush::Daemon.common_init
      expect(Process).to receive(:daemon)
      Rpush::Daemon.start
    end

    it "does not fork into a daemon if the foreground option is true" do
      Rpush.config.foreground = true
      expect(Process).to_not receive(:daemon)
      Rpush::Daemon.start
    end

    it "does not fork into a daemon if the push option is true" do
      Rpush.config.push = true
      expect(Process).to_not receive(:daemon)
      Rpush::Daemon.start
    end

    it "does not fork into a daemon if the embedded option is true" do
      Rpush.config.embedded = true
      expect(Process).to_not receive(:daemon)
      Rpush::Daemon.start
    end
  end

  it 'releases the store connection' do
    Rpush::Daemon.store = double
    expect(Rpush::Daemon.store).to receive(:release_connection)
    Rpush::Daemon.start
  end

  it 'sets up setup signal traps' do
    expect(Rpush::Daemon::SignalHandler).to receive(:start)
    Rpush::Daemon.start
  end

  it 'instantiates the store' do
    Rpush.config.client = :active_record
    Rpush::Daemon.start
    expect(Rpush::Daemon.store).to be_kind_of(Rpush::Daemon::Store::ActiveRecord)
  end

  it 'initializes plugins' do
    plugin = Rpush.plugin(:test)
    did_init = false
    plugin.init { did_init = true }
    Rpush::Daemon.common_init
    expect(did_init).to eq(true)
  end

  it 'logs an error if the store cannot be loaded' do
    Rpush.config.client = :foo_bar
    expect(Rpush.logger).to receive(:error).with(kind_of(LoadError))
    allow(Rpush::Daemon).to receive(:exit) { Rpush::Daemon.store = double.as_null_object }
    Rpush::Daemon.start
  end

  it "writes the process ID to the PID file" do
    expect(Rpush::Daemon).to receive(:write_pid_file)
    Rpush::Daemon.start
  end

  it "logs an error if the PID file could not be written" do
    Rpush.config.pid_file = '/rails_root/rpush.pid'
    allow(File).to receive(:open).and_raise(Errno::ENOENT)
    expect(logger).to receive(:error).with(%r{Failed to write PID to '/rails_root/rpush\.pid'})
    Rpush::Daemon.start
  end

  it "starts the feeder" do
    expect(Rpush::Daemon::Feeder).to receive(:start)
    Rpush::Daemon.start
  end

  it "syncs apps" do
    expect(Rpush::Daemon::Synchronizer).to receive(:sync)
    Rpush::Daemon.start
  end

  describe "shutdown" do
    it "stops the feeder" do
      expect(Rpush::Daemon::Feeder).to receive(:stop)
      Rpush::Daemon.shutdown
    end

    it "stops the app runners" do
      expect(Rpush::Daemon::AppRunner).to receive(:stop)
      Rpush::Daemon.shutdown
    end

    it "removes the PID file if one was written" do
      Rpush.config.pid_file = "/rails_root/rpush.pid"
      allow(File).to receive(:exist?) { true }
      expect(File).to receive(:delete).with("/rails_root/rpush.pid")
      Rpush::Daemon.shutdown
    end

    it "does not attempt to remove the PID file if it does not exist" do
      allow(File).to receive(:exist?) { false }
      expect(File).to_not receive(:delete)
      Rpush::Daemon.shutdown
    end

    it "does not attempt to remove the PID file if one was not written" do
      Rpush.config.pid_file = nil
      expect(File).to_not receive(:delete)
      Rpush::Daemon.shutdown
    end
  end
end
