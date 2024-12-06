require 'unit_spec_helper'

describe Rpush, 'apns_feedback' do
  let!(:apns_app) { Rpush::Apns::App.create!(apns_app_params) }
  let(:apns_app_params) do
    {
      name: 'test',
      environment: 'production',
      certificate: TEST_CERT
    }
  end
  let!(:gcm_app) { Rpush::Gcm::App.create!(name: 'MyApp', auth_key: 'abc123') }

  let(:receiver) { double(check_for_feedback: nil) }

  before do
    allow(Rpush::Daemon::Apns::FeedbackReceiver).to receive(:new) { receiver }
  end

  it 'initializes the daemon' do
    expect(Rpush::Daemon).to receive(:common_init)
    Rpush.apns_feedback
  end

  it 'checks feedback for each app' do
    expect(Rpush::Daemon::Apns::FeedbackReceiver).to receive(:new).with(apns_app).and_return(receiver)
    expect(receiver).to receive(:check_for_feedback)
    Rpush.apns_feedback
  end

  context 'feedback disabled' do
    let(:apns_app_params) { super().merge(feedback_enabled: false) }

    it 'does not initialize feedback receiver' do
      expect(Rpush::Daemon::Apns::FeedbackReceiver).not_to receive(:new)
      Rpush.apns_feedback
    end
  end
end
