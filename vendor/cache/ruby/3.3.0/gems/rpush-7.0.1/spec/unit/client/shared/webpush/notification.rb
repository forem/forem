require 'unit_spec_helper'

shared_examples 'Rpush::Client::Webpush::Notification' do
  subject(:notification) { described_class.new }

  describe 'notification attributes' do
    describe 'data' do
      subject { described_class.new(data: { message: 'test', urgency: 'normal' } ) }
      it 'has a message' do
        expect(subject.message).to eq "test"
      end
      it 'has an urgency' do
        expect(subject.urgency).to eq "normal"
      end
    end

    describe 'subscription' do
      let(:subscription){ { endpoint: 'https://push.example.org/foo', keys: {'foo' => 'bar'}} }
      subject { described_class.new(registration_ids: [subscription]) }

      it "has a subscription" do
        expect(subject.subscription).to eq({ endpoint: 'https://push.example.org/foo', keys: {foo: 'bar'} })
      end
    end
  end


  describe 'validates' do
    let(:app) { Rpush::Webpush::App.create!(name: 'MyApp', vapid_keypair: VAPID_KEYPAIR) }

    describe 'data' do
      subject { described_class.new(app: app, registration_ids: [{endpoint: 'https://push.example.org/foo', keys: {'foo' => 'bar'}}]) }
      it 'validates presence' do
        is_expected.not_to be_valid
        expect(subject.errors[:data]).to eq ["can't be blank"]
      end

      it "has a 'data' payload limit of 4096 bytes" do
        subject.data = { message: 'a' * 4096 }
        is_expected.not_to be_valid
        expected_errors = ["Notification payload data cannot be larger than 4096 bytes."]
        expect(subject.errors[:base]).to eq expected_errors
      end
    end

    describe 'registration_ids' do
      subject { described_class.new(app: app, data: { message: 'test' }) }
      it 'validates presence' do
        is_expected.not_to be_valid
        expect(subject.errors[:registration_ids]).to eq ["can't be blank"]
      end

      it 'limits the number of registration ids to exactly 1' do
        subject.registration_ids = [{endpoint: 'string', keys: { 'a' => 'hash' }}] * 2
        is_expected.not_to be_valid
        expected_errors = ["Number of registration_ids cannot be larger than 1."]
        expect(subject.errors[:base]).to eq expected_errors
      end

      it 'validates the structure of the registration' do
        subject.registration_ids = ['a']
        is_expected.not_to be_valid
        expect(subject.errors[:base]).to eq [
          "Registration must have :endpoint (String) and :keys (Hash) keys"
        ]

        subject.registration_ids = [{endpoint: 'string', keys: { 'a' => 'hash' }}]
        is_expected.to be_valid
      end
    end

    describe 'time_to_live' do
      subject { described_class.new(app: app, data: { message: 'test' }, registration_ids: [{endpoint: 'https://push.example.org/foo', keys: {'foo' => 'bar'}}]) }

      it 'should be > 0' do
        subject.time_to_live = -1
        is_expected.not_to be_valid
        expect(subject.errors[:time_to_live]).to eq ['must be greater than 0']
      end
    end

  end
end
