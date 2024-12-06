require 'spec_helper'

describe 'singleton null object' do
  subject(:null_class) do
    Naught.build(&:singleton)
  end

  it 'does not respond to .new' do
    expect { null_class.new }.to raise_error(NoMethodError)
  end

  it 'has only one instance' do
    null1 = null_class.instance
    null2 = null_class.instance
    expect(null1).to be(null2)
  end

  it 'can be cloned' do
    null = null_class.instance
    expect(null.clone).to be(null)
  end

  it 'can be duplicated' do
    null = null_class.instance
    expect(null.dup).to be(null)
  end
  it 'aliases .instance to .get' do
    expect(null_class.get).to be null_class.instance
  end
  it 'permits arbitrary arguments to be passed to .get' do
    null_class.get(42, :foo => 'bar')
  end
end
