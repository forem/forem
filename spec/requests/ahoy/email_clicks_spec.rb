require "rails_helper"

RSpec.describe "AhoyEmails" do
  describe "POST /email_clicks" do
    let(:token) { "test_token" }
    let(:campaign) { "test_campaign" }
    let(:url) { "http://example.com" }
    let(:signature) { AhoyEmail::Utils.signature(token: token, campaign: campaign, url: url) }

    before do
      # Stub the publish method
      allow(AhoyEmail::Utils).to receive(:publish).and_return(true)
    end

    context "with a valid signature" do
      it "publishes a click event and returns http ok" do
        # Stub the publish method to prevent external calls
        controller = an_instance_of(Ahoy::EmailClicksController)
        allow(AhoyEmail::Utils).to receive(:publish).and_return(true)

        post ahoy_email_clicks_path, params: { t: token, c: campaign, u: url, s: signature }

        expect(response).to have_http_status(:ok)
        expect(AhoyEmail::Utils).to have_received(:publish)
          .with(:click,
                hash_including(token: token, campaign: campaign, url: url, controller: controller))
      end
    end

    context "with an invalid signature" do
      it "returns http forbidden" do
        # Use a clearly invalid signature
        invalid_signature = "invalid"

        post ahoy_email_clicks_path, params: { t: token, c: campaign, u: url, s: invalid_signature }

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq("Invalid signature")
        # Ensure publish method was not called
        expect(AhoyEmail::Utils).not_to have_received(:publish)
      end
    end
  end
end
