require "rails_helper"

RSpec.describe "Webhooks::MailchimpUnsubscribesController", type: :request do
  let(:user) { create(:user, email_digest_periodic: true) }

  describe "POST /webhooks/mailchimp/:secret/unsubscribe" do
    let(:secret) { "secret" }
    let(:params) { { data: { email: user.email } } }

    before do
      allow(SiteConfig).to receive(:mailchimp_webhook_secret).and_return(secret)
    end

    it "return not authorized if the secret is incorrect" do
      expect do
        post "/webhooks/mailchimp/wrong_secret/unsubscribe", params: params
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "unsubscribes the user if the secret is correct" do
      expect do
        post "/webhooks/mailchimp/#{secret}/unsubscribe", params: params
      end.to change { user.reload.email_digest_periodic }.from(true).to(false)
    end
  end
end
