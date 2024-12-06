require 'spec_helper'

describe 'Null()' do
  include ConvertableNull::Conversions

  specify 'given no input, returns a null object' do
    expect(Null().class).to be(ConvertableNull)
  end

  specify 'given nil, returns a null object' do
    expect(Null(nil).class).to be(ConvertableNull)
  end

  specify 'given a null object, returns the same null object' do
    null = ConvertableNull.get
    expect(Null(null)).to be(null)
  end

  specify 'given anything in null_equivalents, returns a null object' do
    expect(Null('').class).to be(ConvertableNull)
  end

  specify 'given anything else, raises an ArgumentError' do
    expect { Null(false) }.to raise_error(ArgumentError)
    expect { Null('hello') }.to raise_error(ArgumentError)
  end

  it 'generates null objects with useful trace info' do
    null, line = Null(), __LINE__ # rubocop:disable ParallelAssignment
    expect(null.__file__).to eq(__FILE__)
    expect(null.__line__).to eq(line)
  end
end
