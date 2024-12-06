# frozen_string_literal: true

require 'spec_helper'

module PersistenceSpec
  class MockModel
    include Modis::Model

    attribute :name, :string, default: 'Ian'
    attribute :age, :integer
    validates :name, presence: true

    before_create :test_before_create
    after_create :test_after_create

    before_update :test_before_update
    after_update :test_after_update

    before_save :test_before_save
    after_save :test_after_save

    def called_callbacks
      @called_callbacks ||= []
    end

    def test_after_create
      called_callbacks << :test_after_create
    end

    def test_before_create
      called_callbacks << :test_before_create
    end

    def test_after_update
      called_callbacks << :test_after_update
    end

    def test_before_update
      called_callbacks << :test_before_update
    end

    def test_after_save
      called_callbacks << :test_after_save
    end

    def test_before_save
      called_callbacks << :test_before_save
    end
  end

  class MockModelNoAllIndex < MockModel
    enable_all_index false
  end
end

describe Modis::Persistence do
  let(:model) { PersistenceSpec::MockModel.new }

  describe 'namespaces' do
    it 'returns the namespace' do
      expect(PersistenceSpec::MockModel.namespace).to eq('persistence_spec:mock_model')
    end

    it 'returns the absolute namespace' do
      expect(PersistenceSpec::MockModel.absolute_namespace).to eq('modis:persistence_spec:mock_model')
    end

    it 'allows the namespace to be set explicitly' do
      PersistenceSpec::MockModel.namespace = 'other'
      expect(PersistenceSpec::MockModel.absolute_namespace).to eq('modis:other')
    end

    after { PersistenceSpec::MockModel.namespace = nil }
  end

  it 'returns a key' do
    model.save!
    expect(model.key).to eq('modis:persistence_spec:mock_model:1')
  end

  it 'returns a nil key if not saved' do
    expect(model.key).to be_nil
  end

  it 'works with ActiveModel dirty tracking' do
    expect { model.name = 'Kyle' }.to change(model, :changed).to(['name'])
    expect(model.name_changed?).to be true
  end

  it 'resets dirty tracking when saved' do
    model.name = 'Kyle'
    expect(model.name_changed?).to be true
    model.save!
    expect(model.name_changed?).to be false
  end

  it 'resets dirty tracking when created' do
    model = PersistenceSpec::MockModel.create!(name: 'Ian')
    expect(model.name_changed?).to be false
  end

  it 'does not identify an attribute as changed if the value is the default' do
    expect(model.class.attributes_with_defaults['name']).to eq('Ian')
    expect(model.name).to eq('Ian')
    expect(model.name_changed?).to be false
  end

  it 'is persisted' do
    expect(model.persisted?).to be true
  end

  it 'does not track the ID if the underlying Redis command failed' do
    redis = double(hmset: double(value: nil), sadd: nil)
    if Gem::Version.new(Redis::VERSION) > Gem::Version.new('4.6.0')
      expect(model.class).to receive(:transaction).and_yield(Redis::PipelinedConnection.new(Redis::Pipeline::Multi.new(redis)))
      expect(redis).to receive(:pipelined).and_yield(Redis::PipelinedConnection.new(Redis::Pipeline.new(redis)))
    else
      expect(model.class).to receive(:transaction).and_yield(redis)
      expect(redis).to receive(:pipelined).and_yield(redis)
    end
    model.save
    expect { model.class.find(model.id) }.to raise_error(Modis::RecordNotFound)
  end

  it 'does not perform validation if validate: false' do
    model.name = nil
    expect(model.valid?).to be false
    expect { model.save!(validate: false) }.to_not raise_error
    model.reload
    expect(model.name).to be_nil

    expect(model.save(validate: false)).to be true
  end

  describe 'an existing record' do
    it 'only updates dirty attributes' do
      model.name = 'Ian'
      model.age = 10
      model.save!
      model.age = 11
      redis = double
      expect(redis).to receive(:hmset).with("modis:persistence_spec:mock_model:1", ["age", "\v"]).and_return(double(value: 'OK'))
      if Gem::Version.new(Redis::VERSION) > Gem::Version.new('4.6.0')
        expect(model.class).to receive(:transaction).and_yield(Redis::PipelinedConnection.new(Redis::Pipeline::Multi.new(redis)))
        expect(redis).to receive(:pipelined).and_yield(Redis::PipelinedConnection.new(Redis::Pipeline.new(redis)))
      else
        expect(model.class).to receive(:transaction).and_yield(redis)
        expect(redis).to receive(:pipelined).and_yield(redis)
      end
      model.save!
      expect(model.age).to eq(11)
    end
  end

  describe 'reload' do
    it 'reloads attributes' do
      model.save!
      model2 = model.class.find(model.id)
      model2.name = 'Changed'
      model2.save!
      expect { model.reload }.to change(model, :name).to('Changed')
    end

    it 'resets dirty tracking' do
      model.save!
      model.name = 'Foo'
      expect(model.name_changed?).to be true
      model.reload
      expect(model.name_changed?).to be false
    end

    it 'raises an error if the record has not been saved' do
      expect { model.reload }.to raise_error(Modis::RecordNotFound, "Couldn't find PersistenceSpec::MockModel without an ID")
    end
  end

  describe 'callbacks' do
    it 'preserves dirty state for the duration of the callback life cycle'
    it 'halts the chain if a callback returns false'

    describe 'a new record' do
      it 'calls the before_create callback' do
        model.save!
        expect(model.called_callbacks).to include(:test_before_create)
      end

      it 'calls the after create callback' do
        model.save!
        expect(model.called_callbacks).to include(:test_after_create)
      end
    end

    describe 'an existing record' do
      before { model.save! }

      it 'calls the before_update callback' do
        model.save!
        expect(model.called_callbacks).to include(:test_before_update)
      end

      it 'calls the after update callback' do
        model.save!
        expect(model.called_callbacks).to include(:test_after_update)
      end
    end

    it 'calls the before_save callback' do
      model.save!
      expect(model.called_callbacks).to include(:test_before_save)
    end

    it 'calls the after save callback' do
      model.save!
      expect(model.called_callbacks).to include(:test_after_save)
    end
  end

  describe 'create' do
    it 'resets dirty tracking' do
      model = PersistenceSpec::MockModel.create(name: 'Ian')
      expect(model.name_changed?).to be false
    end

    describe 'a valid model' do
      it 'returns the created model' do
        model = PersistenceSpec::MockModel.create(name: 'Ian')
        expect(model.valid?).to be true
        expect(model.new_record?).to be false
      end
    end

    describe 'an invalid model' do
      it 'returns the unsaved model' do
        model = PersistenceSpec::MockModel.create(name: nil)
        expect(model.valid?).to be false
        expect(model.new_record?).to be true
      end
    end
  end

  describe 'update_attribute' do
    it 'does not perform validation' do
      model.name = nil
      expect(model.valid?).to be false
      model.name = 'Test'
      model.update_attribute(:name, nil)
    end

    it 'invokes callbacks' do
      model.update_attribute(:name, 'Derp')
      expect(model.called_callbacks).to_not be_empty
    end

    it 'updates all dirty attributes' do
      model.age = 29
      model.update_attribute(:name, 'Derp')
      model.reload
      expect(model.age).to eq 29
    end
  end

  describe 'update!' do
    it 'updates the given attributes' do
      model.update!(name: 'Derp', age: 29)
      model.reload
      expect(model.name).to eq 'Derp'
      expect(model.age).to eq 29
    end

    it 'invokes callbacks' do
      model.update!(name: 'Derp')
      expect(model.called_callbacks).to_not be_empty
    end

    it 'updates all dirty attributes' do
      model.age = 29
      model.update!(name: 'Derp')
      model.reload
      expect(model.age).to eq 29
    end

    it 'raises an error if the model is invalid' do
      expect do
        model.update!(name: nil).to be false
      end.to raise_error(Modis::RecordInvalid)
    end
  end

  describe 'update_attributes!' do
    around(:each) { |example| ActiveSupport::Deprecation.silence { example.run } }

    it 'updates the given attributes' do
      model.update_attributes!(name: 'Derp', age: 29)
      model.reload
      expect(model.name).to eq 'Derp'
      expect(model.age).to eq 29
    end

    it 'invokes callbacks' do
      model.update_attributes!(name: 'Derp')
      expect(model.called_callbacks).to_not be_empty
    end

    it 'updates all dirty attributes' do
      model.age = 29
      model.update_attributes!(name: 'Derp')
      model.reload
      expect(model.age).to eq 29
    end

    it 'raises an error if the model is invalid' do
      expect do
        model.update_attributes!(name: nil).to be false
      end.to raise_error(Modis::RecordInvalid)
    end
  end

  describe 'update' do
    it 'updates the given attributes' do
      model.update(name: 'Derp', age: 29)
      model.reload
      expect(model.name).to eq('Derp')
      expect(model.age).to eq(29)
    end

    it 'invokes callbacks' do
      model.update(name: 'Derp')
      expect(model.called_callbacks).to_not be_empty
    end

    it 'updates all dirty attributes' do
      model.age = 29
      model.update(name: 'Derp')
      model.reload
      expect(model.age).to eq(29)
    end

    it 'returns false if the model is invalid' do
      expect(model.update(name: nil)).to be false
    end
  end

  describe 'update_attributes' do
    around(:each) { |example| ActiveSupport::Deprecation.silence { example.run } }

    it 'updates the given attributes' do
      model.update_attributes(name: 'Derp', age: 29)
      model.reload
      expect(model.name).to eq('Derp')
      expect(model.age).to eq(29)
    end

    it 'invokes callbacks' do
      model.update_attributes(name: 'Derp')
      expect(model.called_callbacks).to_not be_empty
    end

    it 'updates all dirty attributes' do
      model.age = 29
      model.update_attributes(name: 'Derp')
      model.reload
      expect(model.age).to eq(29)
    end

    it 'returns false if the model is invalid' do
      expect(model.update_attributes(name: nil)).to be false
    end
  end

  describe 'key for all records' do
    let(:all_key_name) { "#{PersistenceSpec::MockModel.absolute_namespace}:all" }

    describe 'when :enable_all_index option is set to false' do
      it 'does not save new record to the *:all key' do
        model = PersistenceSpec::MockModel.create!(name: 'Sage')
        expect(Redis.new.smembers(all_key_name).map(&:to_i)).to include(model.id)
      end
    end

    describe 'when :enable_all_index option is set to false' do
      it 'does not save new record to the *:all key' do
        model = PersistenceSpec::MockModelNoAllIndex.create!(name: 'Alex')
        expect(Redis.new.smembers(all_key_name).map(&:to_i)).to_not include(model.id)
      end
    end
  end
end
