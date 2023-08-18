# frozen_string_literal: true

require 'spec_helper'

module WithModel
  describe ConstantStubber do
    it 'allows calling unstub_const multiple times' do
      stubber = described_class.new('Foo')
      stubber.stub_const(1)
      expect { 2.times { stubber.unstub_const } }.not_to raise_error
    end

    it 'allows calling unstub_const without stub_const' do
      stubber = described_class.new('Foo')
      expect { stubber.unstub_const }.not_to raise_error
    end
  end
end
