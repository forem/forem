require 'spec_helper'

RSpec.describe SmartProperties, 'reader' do
  context "when defining a class with a property with a custom reader" do
    subject(:klass) do
      DummyClass.new do
        property :new, default: false, accepts: [true, false], reader: :new?
      end
    end

    context "an instance of this class" do
      subject(:instance) { klass.new }

      it "should read the property using a custom reader" do
        instance = klass.new new: true
        expect(instance.new?).to eq(true)

        instance.new = false
        expect(instance.new?).to eq(false)
      end

      it "should still read the property with the property name when using the #[] syntax" do
        instance = klass.new new: true
        expect(instance[:new]).to eq(true)

        instance = klass.new new: false
        expect(instance[:new]).to eq(false)
      end
    end
  end
end
