require 'unit_spec_helper'

describe Rpush::Daemon::SignalHandler do
  def signal_handler(sig)
    Process.kill(sig, Process.pid)
    sleep 0.1
  end

  def with_handler_start_stop
    Rpush::Daemon::SignalHandler.start
    yield
  ensure
    Rpush::Daemon::SignalHandler.stop
  end

  describe 'shutdown signals' do
    unless Rpush.jruby? # These tests do not work on JRuby.
      it "shuts down when signaled signaled SIGINT" do
        with_handler_start_stop do
          expect(Rpush::Daemon).to receive(:shutdown)
          signal_handler('SIGINT')
        end
      end

      it "shuts down when signaled signaled SIGTERM" do
        with_handler_start_stop do
          expect(Rpush::Daemon).to receive(:shutdown)
          signal_handler('SIGTERM')
        end
      end
    end
  end

  describe 'config.embedded = true' do
    before { Rpush.config.embedded = true }

    it 'does not trap signals' do
      expect(Signal).not_to receive(:trap)
      Rpush::Daemon::SignalHandler.start
    end
  end

  describe 'HUP' do
    before do
      allow(Rpush::Daemon::Synchronizer).to receive(:sync)
      allow(Rpush::Daemon::Feeder).to receive(:wakeup)
      allow(Rpush::Daemon).to receive_messages(store: double(reopen_log: nil))
    end

    it 'syncs' do
      with_handler_start_stop do
        expect(Rpush::Daemon::Synchronizer).to receive(:sync)
        signal_handler('HUP')
      end
    end

    it 'wakes up the Feeder' do
      with_handler_start_stop do
        expect(Rpush::Daemon::Feeder).to receive(:wakeup)
        signal_handler('HUP')
      end
    end
  end

  describe 'USR2' do
    it 'instructs the AppRunner to print debug information' do
      with_handler_start_stop do
        expect(Rpush::Daemon::AppRunner).to receive(:debug)
        signal_handler('USR2')
      end
    end
  end

  describe 'error handing' do
    let(:error) { StandardError.new('test') }

    before do
      allow(Rpush).to receive_messages(logger: double(error: nil, info: nil, reopen: nil))
      allow(Rpush::Daemon).to receive_messages(store: double(reopen_log: nil))
    end

    it 'logs errors received when handling a signal' do
      allow(Rpush::Daemon::Synchronizer).to receive(:sync).and_raise(error)
      expect(Rpush.logger).to receive(:error).with(error)
      with_handler_start_stop do
        signal_handler('HUP')
      end
    end

    it 'does not interrupt processing of further errors' do
      allow(Rpush::Daemon::Synchronizer).to receive(:sync).and_raise(error)
      expect(Rpush::Daemon::AppRunner).to receive(:debug)
      with_handler_start_stop do
        signal_handler('HUP')
        signal_handler('USR2')
      end
    end
  end
end
