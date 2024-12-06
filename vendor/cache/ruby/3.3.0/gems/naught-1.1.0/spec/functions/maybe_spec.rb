require 'spec_helper'

describe 'Maybe()' do
  include ConvertableNull::Conversions

  specify 'given nil, returns a null object' do
    expect(Maybe(nil).class).to be(ConvertableNull)
  end

  specify 'given a null object, returns the same null object' do
    null = ConvertableNull.get
    expect(Maybe(null)).to be(null)
  end

  specify 'given anything in null_equivalents, returns a null object' do
    expect(Maybe('').class).to be(ConvertableNull)
  end

  specify 'given anything else, returns the input unchanged' do
    expect(Maybe(false)).to be(false)
    str = 'hello'
    expect(Maybe(str)).to be(str)
  end

  it 'generates null objects with useful trace info' do
    null, line = Maybe(), __LINE__ # rubocop:disable ParallelAssignment
    expect(null.__file__).to eq(__FILE__)
    expect(null.__line__).to eq(line)
  end

  it 'also works with blocks' do
    expect(Maybe { nil }.class).to eq(ConvertableNull)
    expect(Maybe { 'foo' }).to eq('foo')
  end
end
