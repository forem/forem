require "rails_helper"

RSpec.describe "EmailSubscriptions", type: :request do
  let(:user) { create(:user) }

  def generate_token(user_id)
    Rails.application.message_verifier(:unsubscribe).generate(
      user_id: user_id,
      email_type: :email_mention_notifications,
      expires_at: Time.now + 2.days,
    )
  end

  describe "GET /email_subscriptions/unsubscribe" do
    it "returns 200 if valid" do
      get email_subscriptions_unsubscribe_url(ut: generate_token(user.id))
      expect(response.status).to be(200)
    end

    it "does unsubscribe the user" do
      get email_subscriptions_unsubscribe_url(ut: generate_token(user.id))
      user.reload
      expect(user.email_mention_notifications).to be(false)
    end

    it "handles error properly" do
      expect { get email_subscriptions_unsubscribe_url }.
        to raise_error(ActionController::RoutingError)
    end

    it "won't work if it's past expireation date" do
      token = generate_token(user.id)
      Timecop.freeze(Date.today + 3) do
        expect { get email_subscriptions_unsubscribe_url(ut: token) }.
          to raise_error(ActionController::RoutingError)
      end
    end
  end
end
