require "rails_helper"

RSpec.describe AttributeCleaner, type: :lib do
  with_model :TestClass do
    table do |t|
      t.string :string_attribute
    end

    model do
      # rubocop:disable RSpec/DescribedClass
      include AttributeCleaner.for(:string_attribute)
      # rubocop:enable RSpec/DescribedClass
    end
  end

  it "adds a before_validation callback to the including model", :aggregate_failures do
    before_validation_cbs = TestClass._validation_callbacks.filter_map do |cb|
      cb.filter if cb.kind == :before
    end

    expect(before_validation_cbs).to eq([:nullify_blank_attributes])
    expect(TestClass.new).to respond_to(:nullify_blank_attributes)
  end

  it "replaces empty strings with nil" do
    test_instance = TestClass.new(string_attribute: "")

    expect { test_instance.validate }
      .to change(test_instance, :string_attribute).from("").to(nil)
  end

  it "replaces blank strings with nil" do
    test_instance = TestClass.new(string_attribute: " ")

    expect { test_instance.validate }
      .to change(test_instance, :string_attribute).from(" ").to(nil)
  end

  it "leaves non-blank attributes unchanged" do
    test_instance = TestClass.new(string_attribute: "Test")

    expect { test_instance.validate }.not_to change(test_instance, :string_attribute)
  end

  it "ignores obsolete attributes" do
    TestClass.include(described_class.for(:non_existing))

    expect { TestClass.new.validate }.not_to raise_error
  end
end
