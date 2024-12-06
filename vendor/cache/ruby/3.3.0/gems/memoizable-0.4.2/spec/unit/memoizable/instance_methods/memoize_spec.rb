# encoding: utf-8

require 'spec_helper'
require File.expand_path('../../fixtures/classes', __FILE__)

describe Memoizable::InstanceMethods, '#memoize' do
  subject { object.memoize(method => value) }

  let(:described_class) { Class.new(Fixture::Object) }
  let(:object)          { described_class.new        }
  let(:method)          { :test                      }

  before do
    described_class.memoize(method)
  end

  context 'when the method is not memoized' do
    let(:value) { String.new }

    it 'sets the memoized value for the method to the value' do
      subject
      expect(object.send(method)).to be(value)
    end

    it_should_behave_like 'a command method'
  end

  context 'when the method is already memoized' do
    let(:value)    { double }
    let(:original) { nil    }

    before do
      object.memoize(method => original)
    end

    it 'raises an exception' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end
