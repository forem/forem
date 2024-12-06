# encoding: utf-8

require 'spec_helper'
require File.expand_path('../../fixtures/classes', __FILE__)

describe Memoizable::InstanceMethods, '#freeze' do
  subject { object.freeze }

  let(:described_class) { Class.new(Fixture::Object) }

  before do
    described_class.memoize(:test)
  end

  let(:object) { described_class.allocate }

  it_should_behave_like 'a command method'

  it 'freezes the object' do
    expect { subject }.to change(object, :frozen?).from(false).to(true)
  end

  it 'allows methods not yet called to be memoized' do
    subject
    expect(object.test).to be(object.test)
  end
end
