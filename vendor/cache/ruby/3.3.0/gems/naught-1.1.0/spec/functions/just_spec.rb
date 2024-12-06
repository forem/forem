require 'spec_helper'

describe 'Just()' do
  include ConvertableNull::Conversions

  specify 'passes non-nullish values through' do
    expect(Just(false)).to be(false)
    str = 'hello'
    expect(Just(str)).to be(str)
  end

  specify 'rejects nullish values' do
    expect { Just(nil) }.to raise_error(ArgumentError)
    expect { Just('') }.to raise_error(ArgumentError)
    expect { Just(ConvertableNull.get) }.to raise_error(ArgumentError)
  end

  it 'also works with blocks' do
    expect { Just { nil }.class }.to raise_error(ArgumentError)
    expect(Just { 'foo' }).to eq('foo')
  end
end
