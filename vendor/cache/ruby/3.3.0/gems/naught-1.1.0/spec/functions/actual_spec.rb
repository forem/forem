require 'spec_helper'

describe 'Actual()' do
  include ConvertableNull::Conversions

  specify 'given a null object, returns nil' do
    null = ConvertableNull.get
    expect(Actual(null)).to be_nil
  end

  specify 'given anything else, returns the input unchanged' do
    expect(Actual(false)).to be(false)
    str = 'hello'
    expect(Actual(str)).to be(str)
    expect(Actual(nil)).to be_nil
  end

  it 'also works with blocks' do
    expect(Actual { ConvertableNull.new }).to be_nil
    expect(Actual { 'foo' }).to eq('foo')
  end
end
