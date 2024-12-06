require 'flipper/types/boolean'

RSpec.describe Flipper::Types::Boolean do
  it 'defaults value to true' do
    boolean = described_class.new
    expect(boolean.value).to be(true)
  end

  it 'allows overriding default value' do
    boolean = described_class.new(false)
    expect(boolean.value).to be(false)
  end

  it 'returns true for nil value' do
    boolean = described_class.new(nil)
    expect(boolean.value).to be(true)
  end

  it 'typecasts value' do
    boolean = described_class.new(1)
    expect(boolean.value).to be(true)
  end
end
