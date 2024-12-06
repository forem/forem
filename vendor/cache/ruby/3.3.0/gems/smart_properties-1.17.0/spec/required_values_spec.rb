require 'spec_helper'

RSpec.describe SmartProperties do
  context "when building a class that has a property which is required and has no default" do
    subject(:klass) { DummyClass.new { property :title, required: true } }

    context 'an instance of this class' do
      it 'should have the correct title when provided with a title during initialization' do
        instance = klass.new title: 'Lorem Ipsum'
        expect(instance.title).to eq('Lorem Ipsum')
        expect(instance[:title]).to eq('Lorem Ipsum')

        instance = klass.new { |i| i.title = 'Lorem Ipsum' }
        expect(instance.title).to eq('Lorem Ipsum')
        expect(instance[:title]).to eq('Lorem Ipsum')
      end

      it "should raise an error stating that required properties are missing when initialized without a title" do
        exception = SmartProperties::InitializationError
        message = "Dummy requires the following properties to be set: title"
        further_expectations = lambda { |error| expect(error.to_hash[:title]).to eq('must be set') }

        expect { klass.new }.to raise_error(exception, message, &further_expectations)
        expect { klass.new {} }.to raise_error(exception, message, &further_expectations)
      end

      it "should not allow to set nil as the property's value" do
        instance = klass.new title: 'Lorem Ipsum'

        exception = SmartProperties::MissingValueError
        message = "Dummy requires the property title to be set"
        further_expectations = lambda do |error|
          expect(error.to_hash[:title]).to eq('must be set')
        end

        expect { instance.title = nil }.to raise_error(exception, message, &further_expectations)
        expect { instance[:title] = nil }.to raise_error(exception, message, &further_expectations)
      end
    end
  end

  context "when building a class that has a property! which is required and has no default" do
    subject(:klass) { DummyClass.new { property! :title } }

    context 'an instance of this class' do
      it 'should have the correct title when provided with a title during initialization' do
        instance = klass.new title: 'Lorem Ipsum'
        expect(instance.title).to eq('Lorem Ipsum')
        expect(instance[:title]).to eq('Lorem Ipsum')

        instance = klass.new { |i| i.title = 'Lorem Ipsum' }
        expect(instance.title).to eq('Lorem Ipsum')
        expect(instance[:title]).to eq('Lorem Ipsum')
      end

      it "should raise an error stating that required properties are missing when initialized without a title" do
        exception = SmartProperties::InitializationError
        message = "Dummy requires the following properties to be set: title"
        further_expectations = lambda { |error| expect(error.to_hash[:title]).to eq('must be set') }

        expect { klass.new }.to raise_error(exception, message, &further_expectations)
        expect { klass.new {} }.to raise_error(exception, message, &further_expectations)
      end

      it "should not allow to set nil as the property's value" do
        instance = klass.new title: 'Lorem Ipsum'

        exception = SmartProperties::MissingValueError
        message = "Dummy requires the property title to be set"
        further_expectations = lambda do |error|
          expect(error.to_hash[:title]).to eq('must be set')
        end

        expect { instance.title = nil }.to raise_error(exception, message, &further_expectations)
        expect { instance[:title] = nil }.to raise_error(exception, message, &further_expectations)
      end
    end
  end

  context "when building a class that has a property name which is only required if the property anonymous is set to false" do
    subject(:klass) do
      DummyClass.new do
        property :name, required: lambda { not anonymous }
        property :anonymous, accepts: [true, false], default: true
      end
    end

    it "should not raise an error when created with no arguments" do
      expect { klass.new }.to_not raise_error
    end

    it "should raise an error indicating that a required property was not specified when created with no name and anonymous being set to false" do
      exception = SmartProperties::InitializationError
      message = "Dummy requires the following properties to be set: name"
      further_expectations = lambda { |error| expect(error.to_hash[:name]).to eq("must be set") }

      expect { klass.new anonymous: false }.to raise_error(exception, message, &further_expectations)
      expect { klass.new { |i| i.anonymous = false } }.to raise_error(exception, message, &further_expectations)
    end

    it "should not raise an error when created with a name and anonymous being set to false" do
      expect { klass.new name: "John Doe", anonymous: false }.to_not raise_error
    end
  end

  context "when building a class that has a property which is required and has false as default" do
    subject(:klass) { DummyClass.new { property :flag, required: true, default: false } }

    context 'an instance of this class' do
      it 'should return true as value for this property if provided with this value for the property during initialization' do
        instance = klass.new flag: true
        expect(instance.flag).to eq(true)
        expect(instance[:flag]).to eq(true)

        instance = klass.new { |i| i.flag = true }
        expect(instance.flag).to eq(true)
        expect(instance[:flag]).to eq(true)
      end

      it 'should return false as value for this property when initialized with no arguments' do
        instance = klass.new
        expect(instance.flag).to eq(false)
        expect(instance[:flag]).to eq(false)
      end
    end
  end

  context "when building a class that has a required property with a default value and a malicious converter that always returns nil" do
    subject(:klass) { DummyClass.new { property :title, required: true, converts: ->(_) { nil }, default: "Lorem Ipsum" } }

    context 'an instance of this class' do
      it "should raise an error when initialized" do
        exception = SmartProperties::MissingValueError
        message = "Dummy requires the property title to be set"
        further_expectations = lambda { |error| expect(error.to_hash[:title]).to eq("must be set") }

        expect { klass.new }.to raise_error(exception, message)
        expect { klass.new(title: 'Lorem Ipsum') }.to raise_error(exception, message, &further_expectations)
      end
    end
  end
end
