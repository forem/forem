require 'logger'
require 'flipper/adapters/instrumented'
require 'flipper/instrumentation/log_subscriber'

RSpec.describe Flipper::Instrumentation::LogSubscriber do
  let(:adapter) do
    memory = Flipper::Adapters::Memory.new
    Flipper::Adapters::Instrumented.new(memory, instrumenter: ActiveSupport::Notifications)
  end
  let(:flipper) do
    Flipper.new(adapter, instrumenter: ActiveSupport::Notifications)
  end

  before do
    Flipper.register(:admins) do |thing|
      thing.respond_to?(:admin?) && thing.admin?
    end

    @io = StringIO.new
    logger = Logger.new(@io)
    logger.formatter = proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }
    described_class.logger = logger
  end

  after do
    described_class.logger = nil
  end

  let(:log) { @io.string }

  context 'feature enabled checks' do
    before do
      clear_logs
      flipper[:search].enabled?
    end

    it 'logs feature calls with result after operation' do
      feature_line = find_line('Flipper feature(search) enabled? false')
      expect(feature_line).to include('[ thing=nil ]')
    end

    it 'logs adapter calls' do
      adapter_line = find_line('Flipper feature(search) adapter(memory) get')
      expect(adapter_line).to include('[ result={')
      expect(adapter_line).to include('} ]')
    end
  end

  context 'feature enabled checks with a thing' do
    let(:user) { Flipper::Types::Actor.new(Flipper::Actor.new('1')) }

    before do
      clear_logs
      flipper[:search].enabled?(user)
    end

    it 'logs thing for feature' do
      feature_line = find_line('Flipper feature(search) enabled?')
      expect(feature_line).to include(user.inspect)
    end
  end

  context 'changing feature enabled state' do
    let(:user) { Flipper::Types::Actor.new(Flipper::Actor.new('1')) }

    before do
      clear_logs
      flipper[:search].enable(user)
    end

    it 'logs feature calls with result in brackets' do
      feature_line = find_line('Flipper feature(search) enable true')
      expect(feature_line).to include("[ thing=#{user.inspect} gate_name=actor ]")
    end

    it 'logs adapter value' do
      adapter_line = find_line('Flipper feature(search) adapter(memory) enable')
      expect(adapter_line).to include('[ result=')
    end
  end

  context 'getting all the features from the adapter' do
    before do
      clear_logs
      flipper.features
    end

    it 'logs adapter calls' do
      adapter_line = find_line('Flipper adapter(memory) features')
      expect(adapter_line).to include('[ result=')
    end
  end

  def find_line(str)
    regex = /#{Regexp.escape(str)}/
    lines = log.split("\n")
    lines.detect { |line| line =~ regex } ||
      raise("Could not find line matching #{str.inspect} in #{lines.inspect}")
  end

  def clear_logs
    @io.string = ''
  end
end
