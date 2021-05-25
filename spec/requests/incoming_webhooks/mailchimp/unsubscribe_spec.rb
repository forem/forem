require "rails_helper"

RSpec.describe "IncomingWebhooks::MailchimpUnsubscribesController", type: :request do
  let(:user) { create(:user, :with_newsletters) }
  let(:secret) { "secret" }

  before do
    allow(Settings::General).to receive(:mailchimp_incoming_webhook_secret).and_return(secret)
  end

  describe "GET /webhooks/mailchimp/:secret/unsubscribe" do
    it "provides a health check endpoint for Mailchimp to verify the webhook" do
      get "/incoming_webhooks/mailchimp/wrong_secret/unsubscribe"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /webhooks/mailchimp/:secret/unsubscribe" do
    let(:list_id) { "1234" }
    let(:params) { { data: { email: user.email, list_id: list_id } } }

    it "return not authorized if the secret is incorrect" do
      expect do
        post "/incoming_webhooks/mailchimp/wrong_secret/unsubscribe", params: params
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "unsubscribes the user if the secret is correct" do
      allow(Settings::General).to receive(:mailchimp_newsletter_id).and_return(list_id)

      expect do
        post "/incoming_webhooks/mailchimp/#{secret}/unsubscribe", params: params
      end.to change { user.reload.email_newsletter }.from(true).to(false)
    end
  end
end
