require 'unit_spec_helper'

shared_examples 'Rpush::Client::Adm::App' do
  subject { described_class.new(name: 'test', environment: 'development', client_id: 'CLIENT_ID', client_secret: 'CLIENT_SECRET') }

  it 'should be valid if properly instantiated' do
    expect(subject).to be_valid
  end

  it 'should be invalid if name' do
    subject.name = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:name]).to eq ["can't be blank"]
  end

  it 'should be invalid if missing client_id' do
    subject.client_id = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:client_id]).to eq ["can't be blank"]
  end

  it 'should be invalid if missing client_secret' do
    subject.client_secret = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:client_secret]).to eq ["can't be blank"]
  end

  describe '#access_token_expired?' do
    before(:each) do
      Timecop.freeze(Time.now)
    end

    after do
      Timecop.return
    end

    it 'should return true if access_token_expiration is nil' do
      expect(subject.access_token_expired?).to eq(true)
    end

    it 'should return true if expired' do
      subject.access_token_expiration = Time.now - 5.minutes
      expect(subject.access_token_expired?).to eq(true)
    end

    it 'should return false if not expired' do
      subject.access_token_expiration = Time.now + 5.minutes
      expect(subject.access_token_expired?).to eq(false)
    end
  end
end
