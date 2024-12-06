require 'unit_spec_helper'

shared_examples 'Rpush::Client::App' do
  context 'validating certificates' do
    it 'rescues from certificate error' do
      app = Rpush::Apns::App.new(name: 'test', environment: 'development', certificate: 'bad')
      expect { app.valid? }.not_to raise_error
      expect(app.valid?).to eq(false)
    end

    it 'raises other errors' do
      app = Rpush::Apns::App.new(name: 'test', environment: 'development', certificate: 'bad')
      allow(OpenSSL::X509::Certificate).to receive(:new).and_raise(NameError, 'simulating no openssl')
      expect { app.valid? }.to raise_error(NameError)
    end
  end
end
