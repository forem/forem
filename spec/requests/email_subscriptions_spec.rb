require "rails_helper"

RSpec.describe "EmailSubscriptions" do
  let(:user) { create(:user) }

  before do
    allow(User).to receive(:find).and_return(user)
  end

  def generate_token(user_id)
    Rails.application.message_verifier(:unsubscribe).generate({
                                                                user_id: user_id,
                                                                email_type: "email_mention_notifications",
                                                                expires_at: 31.days.from_now.iso8601
                                                              })
  end

  describe "GET /email_subscriptions/unsubscribe" do
    it "returns 200 if valid" do
      get email_subscriptions_unsubscribe_url(ut: generate_token(user.id))
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 if token is in legacy Marshal format" do
      secret_generator = Rails.application.message_verifiers.instance_variable_get(:@secret_generator)
      secret = secret_generator.call(:unsubscribe.to_s)
      marshal_verifier = ActiveSupport::MessageVerifier.new(secret, digest: "SHA1", serializer: Marshal)
      legacy_token = marshal_verifier.generate({
                                                 user_id: user.id,
                                                 email_type: "email_mention_notifications",
                                                 expires_at: 31.days.from_now.iso8601
                                               })

      get email_subscriptions_unsubscribe_url(ut: legacy_token)
      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.notification_setting.email_mention_notifications).to be(false)
    end

    it "does unsubscribe the user" do
      get email_subscriptions_unsubscribe_url(ut: generate_token(user.id))
      user.reload
      expect(user.notification_setting.email_mention_notifications).to be(false)
    end

    it "handles error properly" do
      expect { get email_subscriptions_unsubscribe_url }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "won't work if it's past expiration date" do
      token = generate_token(user.id)
      Timecop.freeze(32.days.from_now) do
        get email_subscriptions_unsubscribe_url(ut: token)
        expect(response.body).to include("Token expired or invalid")
      end
    end
  end

  describe "GET /email_subscriptions/stay_subscribed", :proper_status do
    let!(:recipient) { EmailReengagementRecipient.create!(user: user, campaign_key: "c1", sent_at: Time.current) }

    def token_for(id, key, expires_at: 60.days.from_now)
      Rails.application.message_verifier(:email_retain).generate(
        { user_id: id, campaign_key: key, expires_at: expires_at.iso8601 },
      )
    end

    it "records confirmation for a valid token" do
      get stay_subscribed_email_subscriptions_path(rt: token_for(user.id, "c1"))
      expect(response).to have_http_status(:ok)
      expect(recipient.reload.confirmed_at).to be_present
    end

    it "is idempotent (second hit keeps original confirmation)" do
      get stay_subscribed_email_subscriptions_path(rt: token_for(user.id, "c1"))
      first = recipient.reload.confirmed_at
      get stay_subscribed_email_subscriptions_path(rt: token_for(user.id, "c1"))
      expect(recipient.reload.confirmed_at).to eq(first)
    end

    it "rejects an expired token" do
      get stay_subscribed_email_subscriptions_path(rt: token_for(user.id, "c1", expires_at: 1.day.ago))
      expect(recipient.reload.confirmed_at).to be_nil
      expect(response.body).to include(I18n.t("email_subscriptions_controller.invalid_token_heading"))
    end

    it "returns not_found for a tampered token" do
      get stay_subscribed_email_subscriptions_path(rt: "garbage--sig")
      expect(response).to have_http_status(:not_found)
    end
  end
end
