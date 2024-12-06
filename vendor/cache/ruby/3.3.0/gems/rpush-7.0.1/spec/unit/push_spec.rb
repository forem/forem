require 'unit_spec_helper'

describe Rpush, 'push' do
  before do
    allow(Rpush::Daemon::Synchronizer).to receive_messages(sync: nil)
    allow(Rpush::Daemon::AppRunner).to receive_messages(wait: nil)
    allow(Rpush::Daemon::Feeder).to receive_messages(start: nil)
  end

  it 'sets the push config option to true' do
    Rpush.push
    expect(Rpush.config.push).to eq(true)
  end

  it 'initializes the daemon' do
    expect(Rpush::Daemon).to receive(:common_init)
    Rpush.push
  end

  it 'syncs' do
    expect(Rpush::Daemon::Synchronizer).to receive(:sync)
    Rpush.push
  end

  it 'starts the feeder' do
    expect(Rpush::Daemon::Feeder).to receive(:start)
    Rpush.push
  end

  it 'stops on the app runner' do
    expect(Rpush::Daemon::AppRunner).to receive(:stop)
    Rpush.push
  end
end
