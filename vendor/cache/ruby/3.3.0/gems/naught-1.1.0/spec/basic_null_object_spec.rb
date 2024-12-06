require 'spec_helper'

describe 'basic null object' do
  let(:null_class) { Naught.build }
  subject(:null) { null_class.new }

  it 'responds to arbitrary messages and returns nil' do
    expect(null.info).to be_nil
    expect(null.foobaz).to be_nil
    expect(null.to_s).to be_nil
  end

  it 'accepts any arguments for any messages' do
    null.foobaz(1, 2, 3)
  end

  it 'reports that it responds to any message' do
    expect(null).to respond_to(:info)
    expect(null).to respond_to(:foobaz)
    expect(null).to respond_to(:to_s)
  end

  it 'can be inspected' do
    expect(null.inspect).to eq('<null>')
  end

  it 'knows its own class' do
    expect(null.class).to eq(null_class)
  end

  it 'aliases .new to .get' do
    expect(null_class.get.class).to be(null_class)
  end
end
