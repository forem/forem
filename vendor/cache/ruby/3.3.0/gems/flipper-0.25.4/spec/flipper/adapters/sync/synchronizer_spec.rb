require "flipper/adapters/memory"
require "flipper/instrumenters/memory"
require "flipper/adapters/sync/synchronizer"

RSpec.describe Flipper::Adapters::Sync::Synchronizer do
  let(:local) { Flipper::Adapters::Memory.new }
  let(:remote) { Flipper::Adapters::Memory.new }
  let(:local_flipper) { Flipper.new(local) }
  let(:remote_flipper) { Flipper.new(remote) }
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }

  subject { described_class.new(local, remote, instrumenter: instrumenter) }

  it "instruments call" do
    subject.call
    expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

    events = instrumenter.events_by_name("synchronizer_call.flipper")
    expect(events.size).to be(1)
  end

  it "raises errors by default" do
    exception = StandardError.new
    expect(remote).to receive(:get_all).and_raise(exception)

    expect { subject.call }.to raise_error(exception)
  end

  context "when raise disabled" do
    subject do
      options = {
        instrumenter: instrumenter,
        raise: false,
      }
      described_class.new(local, remote, options)
    end

    it "does not raise, but instruments exceptions for visibility" do
      exception = StandardError.new
      expect(remote).to receive(:get_all).and_raise(exception)

      expect { subject.call }.not_to raise_error

      events = instrumenter.events_by_name("synchronizer_exception.flipper")
      expect(events.size).to be(1)

      event = events[0]
      expect(event.payload[:exception]).to eq(exception)
    end
  end

  describe '#call' do
    it 'returns nothing' do
      expect(subject.call).to be(nil)
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)
    end

    it 'syncs each remote feature to local' do
      remote_flipper.enable(:search)
      remote_flipper.enable_percentage_of_time(:logging, 10)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper[:search].boolean_value).to eq(true)
      expect(local_flipper[:logging].percentage_of_time_value).to eq(10)
      expect(local_flipper.features.map(&:key).sort).to eq(%w(logging search))
    end

    it 'adds features in remote that are not in local' do
      remote_flipper.add(:search)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper.features.map(&:key)).to eq(["search"])
    end

    it 'removes features in local that are not in remote' do
      local_flipper.add(:stats)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper.features.map(&:key)).to eq([])
    end
  end
end
