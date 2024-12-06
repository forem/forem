# encoding: utf-8

require 'spec_helper'
require File.expand_path('../../../fixtures/classes', __FILE__)

describe Memoizable::MethodBuilder, '.new' do
  subject { described_class.new(descendant, method_name, freezer) }

  let(:descendant) { Fixture::Object                   }
  let(:freezer)    { lambda { |object| object.freeze } }

  context 'with a zero arity method' do
    let(:method_name) { :zero_arity }

    it { should be_instance_of(described_class) }

    it 'sets the original method' do
      # original method is not memoized
      method = subject.original_method.bind(descendant.new)
      expect(method.call).to_not be(method.call)
    end
  end

  context 'with a one arity method' do
    let(:method_name) { :one_arity }

    it 'raises an exception' do
      expect { subject }.to raise_error(
        described_class::InvalidArityError,
        'Cannot memoize Fixture::Object#one_arity, its arity is 1'
      )
    end
  end
end
