# frozen_string_literal: true

require 'spec_helper'

module FindersSpec
  class User
    include Modis::Model
    self.namespace = 'user'

    attribute :name, :string
    attribute :age, :integer
    attribute :parent_default, :string, default: 'omg'
  end

  class Consumer < User
    attribute :consumed, :boolean
  end

  class Producer < User
    attribute :child_default, :string, default: 'derp'
  end

  class Worker < Producer
  end

  class UserNoAllIndex < User
    enable_all_index false
  end
end

describe Modis::Finder do
  let!(:model) { FindersSpec::User.create!(name: 'Ian', age: 28) }
  let(:found) { FindersSpec::User.find(model.id) }

  it 'finds by ID' do
    expect(found.id).to eq(model.id)
    expect(found.name).to eq(model.name)
    expect(found.age).to eq(model.age)
  end

  it 'finds multiple by ID' do
    model1 = FindersSpec::User.create!(name: 'Ian', age: 28)
    model2 = FindersSpec::User.create!(name: 'Tanya', age: 32)
    model3 = FindersSpec::User.create!(name: 'Kyle', age: 35)
    models = FindersSpec::User.find(model1.id, model2.id, model3.id)
    expect(models).to eq([model1, model2, model3])
  end

  it 'raises an error a record could not be found' do
    expect do
      FindersSpec::User.find(model.id + 1)
    end.to raise_error(Modis::RecordNotFound, "Couldn't find FindersSpec::User with id=#{model.id + 1}")

    expect do
      FindersSpec::User.find(model.id, model.id + 1)
    end.to raise_error(Modis::RecordNotFound, "Couldn't find FindersSpec::User with id=#{model.id + 1}")
  end

  it 'does not flag an attribute as dirty on a found instance' do
    expect(found.id_changed?).to be false
  end

  describe 'all' do
    it 'returns all records' do
      m2 = FindersSpec::User.create!(name: 'Tanya', age: 30)
      m3 = FindersSpec::User.create!(name: 'Kyle', age: 32)
      expect(FindersSpec::User.all).to eq([model, m2, m3])
    end

    it 'does not return a destroyed record' do
      model.destroy
      expect(FindersSpec::User.all).to eq([])
    end

    it 'throws error when enable_all_index option is set to false' do
      FindersSpec::UserNoAllIndex.create!(name: 'Yana')
      expect { FindersSpec::UserNoAllIndex.all }
        .to raise_error(Modis::IndexError)
    end
  end

  it 'identifies a found record as not being new' do
    expect(found.new_record?).to be false
  end

  describe 'Single Table Inheritance' do
    it 'returns the correct namespace' do
      expect(FindersSpec::Consumer.namespace).to eq('user:consumer')
      expect(FindersSpec::Consumer.absolute_namespace).to eq('modis:user:consumer')
      expect(FindersSpec::Producer.namespace).to eq('user:producer')
      expect(FindersSpec::Producer.absolute_namespace).to eq('modis:user:producer')
      expect(FindersSpec::Worker.namespace).to eq('user:producer:worker')
      expect(FindersSpec::Worker.absolute_namespace).to eq('modis:user:producer:worker')
    end

    it 'returns instances of the correct class' do
      FindersSpec::Consumer.create!(name: 'Kyle')
      FindersSpec::Producer.create!(name: 'Tanya')
      FindersSpec::Worker.create!(name: 'Max')

      models = FindersSpec::User.all

      ian = models.find { |model| model.name == 'Ian' }
      kyle = models.find { |model| model.name == 'Kyle' }
      tanya = models.find { |model| model.name == 'Tanya' }
      max = models.find { |model| model.name == 'Max' }

      expect(ian).to be_kind_of(FindersSpec::User)
      expect(kyle).to be_kind_of(FindersSpec::Consumer)
      expect(tanya).to be_kind_of(FindersSpec::Producer)
      expect(max).to be_kind_of(FindersSpec::Worker)

      expect(FindersSpec::User.find(ian.id)).to be_kind_of(FindersSpec::User)
      expect(FindersSpec::User.find(kyle.id)).to be_kind_of(FindersSpec::Consumer)
      expect(FindersSpec::User.find(tanya.id)).to be_kind_of(FindersSpec::Producer)
      expect(FindersSpec::User.find(max.id)).to be_kind_of(FindersSpec::Worker)
    end

    it 'scopes IDs within the parent' do
      user = FindersSpec::User.create!(name: 'Ian')
      consumer = FindersSpec::Consumer.create!(name: 'Kyle')
      producer = FindersSpec::Producer.create!(name: 'Tanya')
      worker = FindersSpec::Worker.create!(name: 'Max')
      expect(user.id).to eq(2)
      expect(consumer.id).to eq(3)
      expect(producer.id).to eq(4)
      expect(worker.id).to eq(5)
    end

    it 'does not return instances of other siblings in all' do
      producer = FindersSpec::Producer.create!(name: 'Tanya')
      expect(FindersSpec::Consumer.all).to_not include(producer)
    end

    it 'does not return instances of subclasses of other siblings in all' do
      worker = FindersSpec::Worker.create!(name: 'Max')
      expect(FindersSpec::Consumer.all).to_not include(worker)
    end

    it 'does not find an instance of a sibling' do
      FindersSpec::Consumer.create!(name: 'Kyle')
      producer = FindersSpec::Producer.create!(name: 'Tanya')
      expect do
        FindersSpec::Consumer.find(producer.id)
      end.to raise_error(Modis::RecordNotFound)
    end

    it 'does not find an instance of a subclass of a sibling' do
      producer = FindersSpec::Worker.create!(name: 'Tanya')
      expect do
        FindersSpec::Consumer.find(producer.id)
      end.to raise_error(Modis::RecordNotFound)
    end

    it 'inherits attributes from the parent' do
      producer = FindersSpec::Producer.create!(name: 'Kyle', consumed: true)
      expect(producer.attributes.keys.sort).to eq(%w[age child_default id name parent_default type])

      worker = FindersSpec::Worker.create!(name: 'Max')
      expect(worker.attributes.keys.sort).to eq(%w[age child_default id name parent_default type])
    end

    it 'inherits default attribute values from the parent' do
      producer = FindersSpec::Producer.create!(name: 'Kyle')
      expect(producer.parent_default).to eq('omg')
      expect(producer.child_default).to eq('derp')

      worker = FindersSpec::Worker.create!(name: 'Max')
      expect(worker.parent_default).to eq('omg')
      expect(worker.child_default).to eq('derp')
    end

    it 'does not find a destroyed child instance on the parent' do
      consumer = FindersSpec::Consumer.create!(name: 'Ian')
      expect(FindersSpec::User.find(consumer.id)).to eq(consumer)
      consumer.destroy
      expect do
        FindersSpec::User.find(consumer.id)
      end.to raise_error(Modis::RecordNotFound)
    end

    describe('backwards compatibility') do
      it 'transparently upgrades old data' do
        consumer = FindersSpec::Consumer.create!(name: 'Ian')
        Modis.with_connection do |redis|
          redis.srem(FindersSpec::Consumer.key_for(:all), consumer.id)
        end
        expect(FindersSpec::Consumer.find(consumer.id)).to eq(consumer)
      end
    end
  end
end
