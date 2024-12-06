require 'unit_spec_helper'

shared_examples 'Rpush::Client::Pushy::App' do
  describe 'validates' do
    subject { described_class.new }

    it 'validates presence of name' do
      is_expected.not_to be_valid
      expect(subject.errors[:name]).to eq ["can't be blank"]
    end

    it 'validates presence of api_key' do
      is_expected.not_to be_valid
      expect(subject.errors[:api_key]).to eq ["can't be blank"]
    end
  end
end
