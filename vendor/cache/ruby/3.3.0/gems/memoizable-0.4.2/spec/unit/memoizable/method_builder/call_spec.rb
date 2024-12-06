# encoding: utf-8

require 'spec_helper'
require File.expand_path('../../fixtures/classes', __FILE__)

describe Memoizable::MethodBuilder, '#call' do
  subject { object.call }

  let(:object)   { described_class.new(descendant, method_name, freezer) }
  let(:freezer)  { lambda { |object| object.freeze }                     }
  let(:instance) { descendant.new                                        }

  let(:descendant) do
    Class.new do
      include Memoizable

      def public_method
        __method__.to_s
      end

      def protected_method
        __method__.to_s
      end
      protected :protected_method

      def private_method
        __method__.to_s
      end
      private :private_method
    end
  end

  shared_examples_for 'Memoizable::MethodBuilder#call' do
    it_should_behave_like 'a command method'

    it 'creates a method that is memoized' do
      subject
      expect(instance.send(method_name)).to be(instance.send(method_name))
    end

    it 'creates a method that returns the expected value' do
      subject
      expect(instance.send(method_name)).to eql(method_name.to_s)
    end

    it 'creates a method that returns a frozen value' do
      subject
      expect(descendant.new.send(method_name)).to be_frozen
    end

    it 'creates a method that does not accept a block' do
      subject
      expect { descendant.new.send(method_name) {} }.to raise_error(
        described_class::BlockNotAllowedError,
        "Cannot pass a block to #{descendant}##{method_name}, it is memoized"
      )
    end
  end

  context 'public method' do
    let(:method_name) { :public_method }

    it_should_behave_like 'Memoizable::MethodBuilder#call'

    it 'creates a public memoized method' do
      subject
      expect(descendant).to be_public_method_defined(method_name)
    end
  end

  context 'protected method' do
    let(:method_name) { :protected_method }

    it_should_behave_like 'Memoizable::MethodBuilder#call'

    it 'creates a protected memoized method' do
      subject
      expect(descendant).to be_protected_method_defined(method_name)
    end

  end

  context 'private method' do
    let(:method_name) { :private_method }

    it_should_behave_like 'Memoizable::MethodBuilder#call'

    it 'creates a private memoized method' do
      subject
      expect(descendant).to be_private_method_defined(method_name)
    end
  end
end
