# encoding: utf-8

require 'spec_helper'

describe Memoizable::ModuleMethods, '#unmemoized_instance_method' do
  subject { object.unmemoized_instance_method(name) }

  let(:object) do
    Class.new do
      include Memoizable

      def initialize
        @foo = 0
      end

      def foo
        @foo += 1
      end

      memoize :foo
    end
  end

  context 'when the method was memoized' do
    let(:name) { :foo }

    it { should be_instance_of(UnboundMethod) }

    it 'returns the original method' do
      # original method is not memoized
      method = subject.bind(object.new)
      expect(method.call).to_not be(method.call)
    end
  end

  context 'when the method was not memoized' do
    let(:name) { :bar }

    it 'raises an exception' do
      expect { subject }.to raise_error(NameError, 'No method bar is memoized')
    end
  end
end
