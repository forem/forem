require "spec_helper"

describe Rolify::Utils do
  class Harness
    extend Rolify::Utils
    define_method(:new_method) { |*_args| true }
    deprecate :old_method, :new_method
  end

  let(:harness) { Harness.new }

  context '#deprecate' do
    it 'calls new method with same arguments' do
      expect(harness).to receive(:warn).once
      expect(harness).to receive(:new_method).once.with(1, 2, 3)
      harness.old_method(1, 2, 3)
    end
  end
end
