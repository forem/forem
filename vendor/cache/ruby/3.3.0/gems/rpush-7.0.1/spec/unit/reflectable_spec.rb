require 'unit_spec_helper'

describe Rpush::Reflectable do
  class TestReflectable
    include Rpush::Reflectable
  end

  let(:logger) { double(error: nil) }
  let(:test_reflectable) { TestReflectable.new }

  before do
    allow(Rpush.reflection_stack[0]).to receive(:__dispatch)
    allow(Rpush).to receive_messages(logger: logger)
  end

  it 'dispatches the given reflection' do
    expect(Rpush.reflection_stack[0]).to receive(:__dispatch).with(:error)
    test_reflectable.reflect(:error)
  end

  it 'logs errors raised by the reflection' do
    error = StandardError.new
    allow(Rpush.reflection_stack[0]).to receive(:__dispatch).and_raise(error)
    expect(Rpush.logger).to receive(:error).with(error)
    test_reflectable.reflect(:error)
  end
end
