require "rails_helper"

RSpec.describe "IncomingWebhooks::MailchimpUnsubscribesController", type: :request do
  let(:user) { create(:user, email_digest_periodic: true) }

  describe "POST /webhooks/mailchimp/:secret/unsubscribe" do
    let(:secret) { "secret" }
    let(:list_id) { "1234" }
    let(:params) { { data: { email: user.email, list_id: list_id } } }

    before do
      allow(SiteConfig).to receive(:mailchimp_incoming_webhook_secret).and_return(secret)
    end

    it "return not authorized if the secret is incorrect" do
      expect do
        post "/incoming_webhooks/mailchimp/wrong_secret/unsubscribe", params: params
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "unsubscribes the user if the secret is correct" do
      SiteConfig.mailchimp_newsletter_id = list_id

      expect do
        post "/incoming_webhooks/mailchimp/#{secret}/unsubscribe", params: params
      end.to change { user.reload.email_newsletter }.from(true).to(false)
    end
  end
end
