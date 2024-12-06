# frozen_string_literal: true

require 'spec_helper'

module IndexSpec
  class MockModel
    include Modis::Model

    attribute :name, :string
    index :name
  end
end

describe Modis::Index do
  let!(:model) { IndexSpec::MockModel.create!(name: 'Ian') }

  describe 'create' do
    it 'adds a new model to the index' do
      index = IndexSpec::MockModel.index_for(:name, 'Ian')
      expect(index).to include(model.id)
    end
  end

  describe 'update' do
    before do
      model.name = 'Kyle'
      model.save!
    end

    it 'adds the model to the new index' do
      index = IndexSpec::MockModel.index_for(:name, 'Kyle')
      expect(index).to include(model.id)
    end

    it 'removes the model from the old index' do
      index = IndexSpec::MockModel.index_for(:name, 'Ian')
      expect(index).to_not include(model.id)
    end
  end

  describe 'destroy' do
    it 'removes a destroyed model id from the index' do
      model.destroy
      index = IndexSpec::MockModel.index_for(:name, 'Ian')
      expect(index).to_not include(model.id)
    end

    it 'does not find a destroyed model' do
      model.destroy
      models = IndexSpec::MockModel.where(name: 'Ian')
      expect(models).to be_empty
    end
  end

  it 'finds by index' do
    models = IndexSpec::MockModel.where(name: 'Ian')
    expect(models.first.name).to eq('Ian')
  end

  it 'finds multiple matches' do
    IndexSpec::MockModel.create!(name: 'Ian')
    models = IndexSpec::MockModel.where(name: 'Ian')
    expect(models.count).to eq(2)
  end

  it 'returns an empty array if there are no results' do
    expect(IndexSpec::MockModel.where(name: 'Foo')).to be_empty
  end

  it 'raises an error when trying to query against multiple indexes' do
    expect { IndexSpec::MockModel.where(name: 'Ian', age: 29) }.to raise_error(Modis::IndexError, 'Queries using multiple indexes is not currently supported.')
  end

  it 'indexes a nil value' do
    model.name = nil
    model.save!
    expect(IndexSpec::MockModel.where(name: nil)).to include(model)
  end

  it 'distinguishes between nil and blank string values' do
    model1 = IndexSpec::MockModel.create!(name: nil)
    model2 = IndexSpec::MockModel.create!(name: "")
    expect(IndexSpec::MockModel.where(name: nil)).to eq([model1])
    expect(IndexSpec::MockModel.where(name: "")).to eq([model2])
  end
end
