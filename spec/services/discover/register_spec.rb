require "rails_helper"

RSpec.describe Discover::Register, type: :service do
  let(:domain) { "https://discover.forem.com" }

  before { stub_const "#{described_class}::FOREM_DISCOVER_URL", domain }

  it "defines FOREM_DISCOVER_URL" do
    expect(described_class.const_defined?(:FOREM_DISCOVER_URL)).to be true
  end

  context "when the API call is successful" do
    before { stub_successful_request }

    it "logs info with the parsed response message" do
      allow(Rails.logger).to receive(:info).with("Forem registered successfully for #{domain}.")
      described_class.call(domain: domain)
      expect(Rails.logger).to have_received(:info).with("Forem registered successfully for #{domain}.")
    end

    it "returns true" do
      result = described_class.call(domain: domain)
      expect(result).to eq true
    end
  end

  context "when there is an error with the API call" do
    before { stub_unsuccessful_request }

    it "raises and logs an error" do
      allow(Rails.logger).to receive(:error)

      expect do
        described_class.call(domain: domain)
      end.to raise_error(Discover::Register::RegisterError, "Discover::Register Error")

      expect(Rails.logger).to have_received(:error)
    end
  end

  def stub_successful_request
    stub_request(:post, domain)
      .to_return(
        status: 200,
        body: {
          message: "Forem registered successfully for #{domain}."
        }.to_json,
      )
  end

  def stub_unsuccessful_request(error = "error")
    stub_request(:post, domain)
      .to_return(
        status: 422,
        body: {
          errors: error
        }.to_json,
      )
  end
end
