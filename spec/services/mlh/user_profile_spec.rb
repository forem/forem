require "rails_helper"

RSpec.describe Mlh::UserProfile, type: :service do
  let(:access_token) { "mlh-access-token" }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    # Local env may have this overriden; return nil so that stubs work
    allow(ApplicationConfig).to receive(:[]).with("MLH_API_BASE_URL").and_return(nil)
  end

  describe ".call" do
    it "maps the payload to profile attributes by default",
       vcr: { cassette_name: "mlh_user_profile" } do
      result = described_class.call(access_token)

      expect(result["location"]).to eq("Brooklyn, NY, US")
      expect(result).not_to have_key("email")
    end

    it "returns the raw payload when mapping is disabled",
       vcr: { cassette_name: "mlh_user_profile" } do
      payload = described_class.new(access_token, mapper: nil).call

      expect(payload["email"]).to eq("mlh-user@example.com")
      expect(payload.dig("education", 0, "school_name")).to eq("Acadia University")
    end

    it "requests /v4/users/me with the expandable fields" do
      url = "https://api.mlh.com/v4/users/me" \
            "?expand[]=address&expand[]=education&expand[]=professional_experience"
      stub_request(:get, url).to_return(status: 200, body: "{}",
                                        headers: { "Content-Type" => "application/json" })

      described_class.call(access_token)

      expect(WebMock).to have_requested(:get, url)
    end

    it "raises ArgumentError when there is no token to fetch with" do
      expect { described_class.call(nil) }.to raise_error(ArgumentError)
    end

    it "propagates a fetch error" do
      client = instance_double(Mlh::ApiClient)
      allow(Mlh::ApiClient).to receive(:new).and_return(client)
      allow(client).to receive(:get).and_raise(Mlh::ApiClient::RecoverableError)

      expect { described_class.call(access_token) }.to raise_error(Mlh::ApiClient::RecoverableError)
    end
  end
end
