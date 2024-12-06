# encoding: utf-8

require 'spec_helper'

describe Memoizable::MethodBuilder, '#original_method' do
  subject { object.original_method }

  let(:object)      { described_class.new(descendant, method_name, freezer) }
  let(:method_name) { :foo                                                  }
  let(:freezer)     { lambda { |object| object.freeze }                     }

  let(:descendant) do
    Class.new do
      def initialize
        @foo = 0
      end

      def foo
        @foo += 1
      end
    end
  end

  it { should be_instance_of(UnboundMethod) }

  it 'returns the original method' do
    # original method is not memoized
    method = subject.bind(descendant.new)
    expect(method.call).to_not be(method.call)
  end
end
