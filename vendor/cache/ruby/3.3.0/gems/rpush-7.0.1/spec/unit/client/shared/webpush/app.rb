require 'unit_spec_helper'

shared_examples 'Rpush::Client::Webpush::App' do
  describe 'validates' do
    subject { described_class.new }

    it 'validates presence of name' do
      is_expected.not_to be_valid
      expect(subject.errors[:name]).to eq ["can't be blank"]
    end

    it 'validates presence of vapid_keypair' do
      is_expected.not_to be_valid
      expect(subject.errors[:vapid_keypair]).to eq ["can't be blank"]
    end

    it 'should require the vapid keypair to have subject, public and private key' do
      subject.vapid_keypair = {}.to_json
      is_expected.not_to be_valid
      expect(subject.errors[:vapid_keypair].sort).to eq [
        'must have a private_key entry',
        'must have a public_key entry',
        'must have a subject entry',
      ]
    end

    it 'should require valid json for the keypair' do
      subject.vapid_keypair = 'invalid'
      is_expected.not_to be_valid
      expect(subject.errors[:vapid_keypair].sort).to eq [ 'must be valid JSON' ]
    end
  end
end
