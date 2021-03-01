require "rails_helper"

RSpec.describe "UserSubscriptions", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /user_subscriptions/subscribed - UserSubscriptions#subscribed" do
    it "raises an error for missing params" do
      expect { get subscribed_user_subscriptions_path, params: {} }.to raise_error(ActionController::ParameterMissing)
    end

    it "returns true if a user is already subscribed" do
      article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)

      create(:user_subscription,
             subscriber_id: user.id,
             subscriber_email: user.email,
             author_id: article.user_id,
             user_subscription_sourceable: article)

      valid_params = { source_type: article.class_name, source_id: article.id }
      get subscribed_user_subscriptions_path, params: valid_params

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["is_subscribed"]).to eq true
    end

    it "returns false if a user is not already subscribed" do
      valid_params = { source_type: "Article", source_id: 999 }
      get subscribed_user_subscriptions_path, params: valid_params

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["is_subscribed"]).to eq false
    end
  end

  describe "POST /user_subscriptions - UserSubscriptions#create" do
    it "creates a UserSubscription" do
      article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
      valid_attributes = { source_type: article.class_name, source_id: article.id, subscriber_email: user.email }
      expect do
        post user_subscriptions_path,
             headers: { "Content-Type" => "application/json" },
             params: { user_subscription: valid_attributes }.to_json
      end.to change(UserSubscription, :count).by(1)

      user_subscription = UserSubscription.last
      expect(user_subscription.subscriber_id).to eq user.id
      expect(user_subscription.author_id).to eq article.user_id
      expect(user_subscription.user_subscription_sourceable_type).to eq article.class_name
      expect(user_subscription.user_subscription_sourceable_id).to eq article.id
    end

    it "returns an error for an invalid source_type" do
      invalid_source_type_attributes = { source_type: "NonExistentSourceType", source_id: "1",
                                         subscriber_email: user.email }
      expect do
        post user_subscriptions_path,
             headers: { "Content-Type" => "application/json" },
             params: { user_subscription: invalid_source_type_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Invalid source_type.")
    end

    it "returns an error for a source that can't be found" do
      invalid_source_attributes = { source_type: "Article", source_id: "99999999" }
      expect do
        post user_subscriptions_path,
             headers: { "Content-Type" => "application/json" },
             params: { user_subscription: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Source not found.")
    end

    it "returns an error for an inactive source" do
      unpublished_article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true,
                                                                                    published: false)
      invalid_source_attributes = { source_type: unpublished_article.class_name, source_id: unpublished_article.id,
                                    subscriber_email: user.email }
      expect do
        post user_subscriptions_path,
             headers: { "Content-Type" => "application/json" },
             params: { user_subscription: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Source not found. Please make sure your Article is active!")
    end

    it "returns an error for a source that doesn't have the UserSubscription liquid tag enabled" do
      article = create(:article, :with_user_subscription_tag_role_user)
      invalid_source_attributes = { source_type: article.class_name, source_id: article.id,
                                    subscriber_email: user.email }
      expect do
        post user_subscriptions_path,
             headers: { "Content-Type" => "application/json" },
             params: { user_subscription: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("User subscriptions are not enabled for the source.")
    end

    it "returns an error for an invalid UserSubscription" do
      article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
      # Create the UserSubscription directly so it results in a
      # duplicate/invalid record and returns an error. This mimics a user
      # trying to subscribe to the same user via the same source, twice.
      create(:user_subscription,
             subscriber_id: user.id,
             subscriber_email: user.email,
             author_id: article.user.id,
             user_subscription_sourceable: article)

      invalid_source_attributes = { source_type: article.class_name, source_id: article.id,
                                    subscriber_email: user.email }

      expect do
        post user_subscriptions_path,
             headers: { "Content-Type" => "application/json" },
             params: { user_subscription: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Subscriber has already been taken")
    end

    # TODO: [@forem/delightful]: re-enable this once email confirmation is re-enabled
    xit "returns an error for an email mismatch" do
      article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
      invalid_source_attributes = { source_type: article.class_name, source_id: article.id,
                                    subscriber_email: "old_email@test.com" }

      expect do
        post user_subscriptions_path,
             headers: { "Content-Type" => "application/json" },
             params: { user_subscription: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Subscriber email mismatch.")
    end

    it "returns an error for a subscriber that signed up with Apple" do
      allow(user).to receive(:email).and_return("test@privaterelay.appleid.com")
      article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
      valid_source_attributes = { source_type: article.class_name, source_id: article.id, subscriber_email: user.email }

      expect do
        post user_subscriptions_path,
             headers: { "Content-Type" => "application/json" },
             params: { user_subscription: valid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      error_message = "Subscriber email Can't subscribe with an Apple private relay. Please update email."
      expect(response.parsed_body["error"]).to include(error_message)
    end
  end

  context "when rate limiting" do
    let(:rate_limiter) { RateLimitChecker.new(user) }
    let(:article) { create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true) }
    let(:valid_attributes) { { source_type: article.class_name, source_id: article.id, subscriber_email: user.email } }

    before { allow(RateLimitChecker).to receive(:new).and_return(rate_limiter) }

    it "increments rate limit for user_subscription_creation" do
      allow(rate_limiter).to receive(:track_limit_by_action)
      post user_subscriptions_path,
           headers: { "Content-Type" => "application/json" },
           params: { user_subscription: valid_attributes }.to_json

      expect(rate_limiter).to have_received(:track_limit_by_action).with(:user_subscription_creation)
    end

    it "returns a 429 status when rate limit is reached" do
      allow(rate_limiter).to receive(:limit_by_action).and_return(true)
      post user_subscriptions_path,
           headers: { "Content-Type" => "application/json" },
           params: { user_subscription: valid_attributes }.to_json

      expect(response).to have_http_status(:too_many_requests)
      expected_retry_after = RateLimitChecker::ACTION_LIMITERS.dig(:user_subscription_creation, :retry_after)
      expect(response.headers["Retry-After"]).to eq(expected_retry_after)
    end
  end
end
