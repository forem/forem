$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'pp'
require 'pathname'
FlipperRoot = Pathname(__FILE__).dirname.join('..').expand_path

require 'rubygems'
require 'bundler'

Bundler.setup(:default)

require 'debug'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

require 'flipper'
require 'flipper/api'
require 'flipper/spec/shared_adapter_specs'
require 'flipper/ui'

Dir[FlipperRoot.join('spec/support/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.before(:example) do
    Flipper::Cloud::Registry.default.clear if defined?(Flipper::Cloud)
    Flipper.unregister_groups
    Flipper.configuration = nil
  end

  config.disable_monkey_patching!

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

RSpec.shared_examples_for 'a percentage' do
  it 'initializes with value' do
    percentage = described_class.new(12)
    expect(percentage).to be_instance_of(described_class)
  end

  it 'converts string values to integers when initializing' do
    percentage = described_class.new('15')
    expect(percentage.value).to eq(15)
  end

  it 'has a value' do
    percentage = described_class.new(19)
    expect(percentage.value).to eq(19)
  end

  it 'raises exception for value higher than 100' do
    expect do
      described_class.new(101)
    end.to raise_error(ArgumentError,
                       'value must be a positive number less than or equal to 100, but was 101')
  end

  it 'raises exception for negative value' do
    expect do
      described_class.new(-1)
    end.to raise_error(ArgumentError,
                       'value must be a positive number less than or equal to 100, but was -1')
  end
end

RSpec.shared_examples_for 'a DSL feature' do
  it 'returns instance of feature' do
    expect(feature).to be_instance_of(Flipper::Feature)
  end

  it 'sets name' do
    expect(feature.name).to eq(:stats)
  end

  it 'sets adapter' do
    expect(feature.adapter.name).to eq(dsl.adapter.name)
  end

  it 'sets instrumenter' do
    expect(feature.instrumenter).to eq(dsl.instrumenter)
  end

  it 'memoizes the feature' do
    expect(dsl.send(method_name, :stats)).to equal(feature)
  end

  it 'raises argument error if not string or symbol' do
    expect do
      dsl.send(method_name, Object.new)
    end.to raise_error(ArgumentError, /must be a String or Symbol/)
  end
end

RSpec.shared_examples_for 'a DSL boolean method' do
  it 'returns boolean with value set' do
    result = subject.send(method_name, true)
    expect(result).to be_instance_of(Flipper::Types::Boolean)
    expect(result.value).to be(true)

    result = subject.send(method_name, false)
    expect(result).to be_instance_of(Flipper::Types::Boolean)
    expect(result.value).to be(false)
  end
end
