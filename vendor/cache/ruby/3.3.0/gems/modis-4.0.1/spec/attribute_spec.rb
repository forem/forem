# frozen_string_literal: true

require 'spec_helper'

module AttributeSpec
  class MockModel
    include Modis::Model

    attribute :name, :string, default: 'Janet'
    attribute :age, :integer, default: 60
    attribute :percentage, :float
    attribute :created_at, :timestamp
    attribute :flag, :boolean
    attribute :array, :array
    attribute :hash, :hash
    attribute :string_or_hash, %i[string hash]
  end
end

describe Modis::Attribute do
  let(:model) { AttributeSpec::MockModel.new }

  it 'defines attributes' do
    model.name = 'bar'
    expect(model.name).to eq('bar')
  end

  it 'applies an default value' do
    expect(model.name).to eq('Janet')
    expect(model.age).to eq(60)
  end

  it 'does not mark an attribute with a default as dirty' do
    expect(model.name_changed?).to be false
  end

  it 'raises an error for an unsupported attribute type' do
    expect do
      module AttributeSpec
        class MockModel
          attribute :unsupported, :symbol
        end
      end.to raise_error(Modis::UnsupportedAttributeType)
    end
  end

  it 'assigns attributes' do
    model.assign_attributes(name: 'bar')
    expect(model.name).to eq 'bar'
  end

  it 'does not attempt to assign attributes that are not defined on the model' do
    model.assign_attributes(missing_attr: 'derp')
    expect(model.respond_to?(:missing_attrexpect)).to be false
  end

  it 'allows an attribute to be nilled' do
    model.name = nil
    model.save!
    expect(model.class.find(model.id).name).to be_nil
  end

  it 'allows an attribute to be a blank string' do
    model.name = ''
    model.save!
    expect(model.class.find(model.id).name).to eq('')
  end

  describe ':string type' do
    it 'is coerced' do
      model.name = 'Ian'
      model.save!
      found = AttributeSpec::MockModel.find(model.id)
      expect(found.name).to eq('Ian')
    end
  end

  describe ':integer type' do
    it 'is coerced' do
      model.age = 18
      model.save!
      found = AttributeSpec::MockModel.find(model.id)
      expect(found.age).to eq(18)
    end
  end

  describe ':float type' do
    it 'is coerced' do
      model.percentage = 18.6
      model.save!
      found = AttributeSpec::MockModel.find(model.id)
      expect(found.percentage).to eq(18.6)
    end
  end

  describe ':timestamp type' do
    it 'is coerced' do
      time = Time.new(2014, 12, 11, 17, 31, 50, '-02:00')
      model.created_at = time
      model.save!
      found = AttributeSpec::MockModel.find(model.id)
      expect(found.created_at).to be_kind_of(Time)
      expect(found.created_at.to_s).to eq(time.to_s)
    end
  end

  describe ':boolean type' do
    describe true do
      it 'is coerced' do
        model.flag = true
        model.save!
        found = AttributeSpec::MockModel.find(model.id)
        expect(found.flag).to be true
      end
    end

    describe false do
      it 'is coerced' do
        model.flag = false
        model.save!
        found = AttributeSpec::MockModel.find(model.id)
        expect(found.flag).to be false
      end
    end

    it 'raises an error if assigned a non-boolean value' do
      expect { model.flag = 'unf!' }.to raise_error(Modis::AttributeCoercionError, "Received value of type 'String', expected 'TrueClass', 'FalseClass' for attribute 'flag'.")
    end
  end

  describe ':array type' do
    it 'is coerced' do
      model.array = [1, 2, 3]
      model.save!
      found = AttributeSpec::MockModel.find(model.id)
      expect(found.array).to eq([1, 2, 3])
    end

    it 'raises an error when assigned another type' do
      expect { model.array = { foo: :bar } }.to raise_error(Modis::AttributeCoercionError, "Received value of type 'Hash', expected 'Array' for attribute 'array'.")
    end
  end

  describe ':hash type' do
    it 'is coerced' do
      model.hash = { foo: :bar }
      model.save!
      found = AttributeSpec::MockModel.find(model.id)
      expect(found.hash).to eq('foo' => 'bar')
    end

    it 'raises an error when assigned another type' do
      expect { model.hash = [] }.to raise_error(Modis::AttributeCoercionError, "Received value of type 'Array', expected 'Hash' for attribute 'hash'.")
    end
  end

  describe 'variable type' do
    it 'is coerced' do
      model.string_or_hash = { foo: :bar }
      model.save!
      found = AttributeSpec::MockModel.find(model.id)
      expect(found.string_or_hash).to eq('foo' => 'bar')

      model.string_or_hash = 'test'
      model.save!
      found = AttributeSpec::MockModel.find(model.id)
      expect(found.string_or_hash).to eq('test')
    end

    it 'raises an error when assigned another type' do
      expect { model.string_or_hash = [] }.to raise_error(Modis::AttributeCoercionError, "Received value of type 'Array', expected 'String', 'Hash' for attribute 'string_or_hash'.")
    end
  end
end
