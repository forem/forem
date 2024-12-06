require 'unit_spec_helper'

describe Rpush, 'embed' do
  before do
    allow(Rpush::Daemon).to receive_messages(start: nil, shutdown: nil)
    allow(Kernel).to receive(:at_exit)
  end

  after { Rpush.shutdown }

  it 'sets the embedded config option to true' do
    Rpush.embed
    expect(Rpush.config.embedded).to eq(true)
  end

  it 'starts the daemon' do
    expect(Rpush::Daemon).to receive(:start)
    Rpush.embed
  end
end

describe Rpush, 'shutdown' do
  before { Rpush.config.embedded = true }

  it 'shuts down the daemon' do
    expect(Rpush::Daemon).to receive(:shutdown)
    Rpush.shutdown
  end
end

describe Rpush, 'sync' do
  before { Rpush.config.embedded = true }

  it 'syncs' do
    expect(Rpush::Daemon::Synchronizer).to receive(:sync)
    Rpush.sync
  end
end

describe Rpush, 'status' do
  before { Rpush.config.embedded = true }

  it 'returns the AppRunner status' do
    expect(Rpush::Daemon::AppRunner).to receive_messages(status: { status: true })
    expect(Rpush.status).to eq(status: true)
  end
end
