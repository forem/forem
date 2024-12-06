# frozen_string_literal: true

require 'spec_helper'

describe 'validations' do
  class TestModel
    include Modis::Model
    attribute :name, :string
    validates :name, presence: true
  end

  let(:model) { TestModel.new }

  it 'responds to valid?' do
    model.name = nil
    expect(model.valid?).to be false
  end

  it 'sets errors on the model' do
    model.name = nil
    model.valid?
    expect(model.errors[:name]).to eq(["can't be blank"])
  end

  describe 'save' do
    it 'returns true if the model is valid' do
      model.name = "Ian"
      expect(model.save).to be true
    end

    it 'returns false if the model is invalid' do
      model.name = nil
      expect(model.save).to be false
    end
  end

  describe 'save!' do
    it 'raises an error if the model is invalid' do
      model.name = nil
      expect do
        expect(model.save!).to be false
      end.to raise_error(Modis::RecordInvalid)
    end
  end

  describe 'create!' do
    it 'raises an error if the record is not valid' do
      expect { TestModel.create!(name: nil) }.to raise_error(Modis::RecordInvalid)
    end
  end
end
