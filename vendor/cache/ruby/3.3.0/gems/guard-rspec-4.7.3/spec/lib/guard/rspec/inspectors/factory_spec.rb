require "guard/compat/test/helper"

require "guard/rspec/inspectors/factory"

RSpec.describe Guard::RSpec::Inspectors::Factory do
  let(:factory) { Guard::RSpec::Inspectors::Factory }
  let(:options) { {} }

  it "can not be instantiated" do
    expect { factory.new(options) }.to raise_error(NoMethodError)
  end

  context "with :focus failed mode and custom options" do
    let(:options) { { failed_mode: :focus, custom: "value" } }

    it "creates FocusedInspector instance with custom options" do
      inspector = factory.create(options)
      expect(inspector).
        to be_an_instance_of(Guard::RSpec::Inspectors::FocusedInspector)
      expect(inspector.options).to eq(options)
    end
  end

  context "with :keep failed mode and custom options" do
    let(:options) { { failed_mode: :keep, custom: "value" } }

    it "creates KeepingInspector instance with custom options" do
      inspector = factory.create(options)
      expect(inspector).
        to be_an_instance_of(Guard::RSpec::Inspectors::KeepingInspector)
      expect(inspector.options).to eq(options)
    end
  end

  context "with :none failed mode and custom options" do
    let(:options) { { failed_mode: :none, custom: "value" } }

    it "creates SimpleInspector instance with custom options" do
      inspector = factory.create(options)
      expect(inspector).
        to be_an_instance_of(Guard::RSpec::Inspectors::SimpleInspector)
      expect(inspector.options).to eq(options)
    end
  end
end
