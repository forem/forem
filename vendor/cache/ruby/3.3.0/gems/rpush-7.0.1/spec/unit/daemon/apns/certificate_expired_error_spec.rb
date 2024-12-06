require 'unit_spec_helper'

describe Rpush::CertificateExpiredError do
  let(:app) { double(name: 'test') }
  let(:error) { Rpush::CertificateExpiredError.new(app, Time.now) }

  it 'returns a message' do
    error.message
    error.to_s
  end
end
