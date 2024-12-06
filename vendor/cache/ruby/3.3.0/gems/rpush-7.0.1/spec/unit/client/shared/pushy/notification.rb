require 'unit_spec_helper'

shared_examples 'Rpush::Client::Pushy::Notification' do
  subject(:notification) { described_class.new }

  describe 'validates' do
    let(:app) { Rpush::Pushy::App.create!(name: 'MyApp', api_key: 'my_api_key') }

    describe 'data' do
      subject { described_class.new(app: app, registration_ids: ['id']) }
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

      it 'limits the number of registration ids to 1000' do
        subject.registration_ids = ['a'] * (1000 + 1)
        is_expected.not_to be_valid
        expected_errors = ["Number of registration_ids cannot be larger than 1000."]
        expect(subject.errors[:base]).to eq expected_errors
      end
    end

    describe 'time_to_live' do
      subject { described_class.new(app: app, data: { message: 'test' }, registration_ids: ['id']) }

      it 'should be > 0' do
        subject.time_to_live = -1
        is_expected.not_to be_valid
        expect(subject.errors[:time_to_live]).to eq ['must be greater than 0']
      end

      it 'should be <= 1.year.seconds' do
        subject.time_to_live = 2.years.seconds.to_i
        is_expected.not_to be_valid
        expect(subject.errors[:time_to_live]).to eq ['The maximum value is 1 year']
      end
    end
  end
end
