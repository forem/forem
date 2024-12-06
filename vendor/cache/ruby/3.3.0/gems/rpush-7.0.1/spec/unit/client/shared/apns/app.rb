require 'unit_spec_helper'

shared_examples 'Rpush::Client::Apns::App' do
  it 'does not validate an app with an invalid certificate' do
    app = described_class.new(name: 'test', environment: 'development', certificate: 'foo')
    app.valid?
    expect(app.errors[:certificate]).to eq ['value must contain a certificate and a private key.']
  end

  it 'validates a certificate without a password' do
    app = described_class.new name: 'test', environment: 'development', certificate: TEST_CERT
    app.valid?
    expect(app.errors[:certificate]).to eq []
  end

  it 'validates a certificate with a password' do
    app = described_class.new name: 'test', environment: 'development',
                              certificate: TEST_CERT_WITH_PASSWORD, password: 'fubar'
    app.valid?
    expect(app.errors[:certificate]).to eq []
  end

  it 'validates a certificate with an incorrect password' do
    app = described_class.new name: 'test', environment: 'development',
                              certificate: TEST_CERT_WITH_PASSWORD, password: 'incorrect'
    app.valid?
    expect(app.errors[:certificate]).to eq ['value must contain a certificate and a private key.']
  end
end
