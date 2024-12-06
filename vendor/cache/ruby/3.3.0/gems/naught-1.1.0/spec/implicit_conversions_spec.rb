require 'spec_helper'

describe 'implicitly convertable null object' do
  subject(:null) { null_class.new }
  let(:null_class) do
    Naught.build(&:define_implicit_conversions)
  end
  it 'implicitly splats the same way an empty array does' do
    a, b = null
    expect(a).to be_nil
    expect(b).to be_nil
  end
  it 'is implicitly convertable to String' do
    expect(instance_eval(null)).to be_nil
  end
  it 'implicitly converts to an empty array' do
    expect(null.to_ary).to eq([])
  end
  it 'implicitly converts to an empty hash' do
    expect(null.to_hash).to eq({})
  end
  it 'implicitly converts to zero' do
    expect(null.to_int).to eq(0)
  end
  it 'implicitly converts to an empty string' do
    expect(null.to_str).to eq('')
  end
end
