require 'flipper/adapters/instrumented'
require 'flipper/instrumentation/statsd'
require 'statsd'

RSpec.describe Flipper::Instrumentation::StatsdSubscriber do
  let(:statsd_client) { Statsd.new }
  let(:socket) { FakeUDPSocket.new }
  let(:adapter) do
    memory = Flipper::Adapters::Memory.new
    Flipper::Adapters::Instrumented.new(memory, instrumenter: ActiveSupport::Notifications)
  end
  let(:flipper) do
    Flipper.new(adapter, instrumenter: ActiveSupport::Notifications)
  end

  let(:user) { user = Flipper::Actor.new('1') }

  before do
    described_class.client = statsd_client
    Thread.current[:statsd_socket] = socket
  end

  after do
    described_class.client = nil
    Thread.current[:statsd_socket] = nil
  end

  def assert_timer(metric)
    regex = /#{Regexp.escape metric}\:\d+\|ms/
    result = socket.buffer.detect { |op| op.first =~ regex }
    expect(result).not_to be_nil
  end

  def assert_counter(metric)
    result = socket.buffer.detect { |op| op.first == "#{metric}:1|c" }
    expect(result).not_to be_nil
  end

  context 'for enabled feature' do
    it 'updates feature metrics when calls happen' do
      flipper[:stats].enable(user)
      assert_timer 'flipper.feature_operation.enable'

      flipper[:stats].enabled?(user)
      assert_timer 'flipper.feature_operation.enabled'
      assert_counter 'flipper.feature.stats.enabled'
    end
  end

  context 'for disabled feature' do
    it 'updates feature metrics when calls happen' do
      flipper[:stats].disable(user)
      assert_timer 'flipper.feature_operation.disable'

      flipper[:stats].enabled?(user)
      assert_timer 'flipper.feature_operation.enabled'
      assert_counter 'flipper.feature.stats.disabled'
    end
  end

  it 'updates adapter metrics when calls happen' do
    flipper[:stats].enable(user)
    assert_timer 'flipper.adapter.memory.enable'

    flipper[:stats].enabled?(user)
    assert_timer 'flipper.adapter.memory.get'

    flipper[:stats].disable(user)
    assert_timer 'flipper.adapter.memory.disable'
  end
end
