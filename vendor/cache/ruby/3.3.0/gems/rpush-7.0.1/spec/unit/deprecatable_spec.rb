require 'unit_spec_helper'

describe Rpush::Deprecatable do
  class HasDeprecatedMethod
    include Rpush::Deprecatable

    def original_called?
      @called == true
    end

    def deprecated_method
      @called = true
    end
    deprecated(:deprecated_method, '4.0')
  end

  let(:klass) { HasDeprecatedMethod.new }

  before do
    allow(Rpush::Deprecation).to receive(:warn)
  end

  it 'warns the method is deprecated when called' do
    expect(Rpush::Deprecation).to receive(:warn).with(/deprecated_method is deprecated and will be removed from Rpush 4\.0\./)
    klass.deprecated_method
  end

  it 'calls the original method' do
    klass.deprecated_method
    expect(klass.original_called?).to eq(true)
  end
end
