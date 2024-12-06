require 'unit_spec_helper'

describe Rpush::Daemon::ProcTitle do
  it 'sets the process title' do
    Rpush.config.embedded = false
    Rpush.config.push = false
    allow(Rpush::Daemon::AppRunner).to receive_messages(total_dispatchers: 2, total_queued: 10)
    expect(Process).to receive(:setproctitle).with('rpush | 10 queued | 2 dispatchers')
    Rpush::Daemon::ProcTitle.update
  end
end
