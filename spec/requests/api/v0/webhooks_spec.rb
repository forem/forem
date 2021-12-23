require "rails_helper"

RSpec.describe "Api::V0::Webhooks", type: :request do
  let(:user) { create(:user) }
  let!(:webhook) do
    create(:webhook_endpoint, user: user, target_url: "https://api.example.com/go")
  end

  describe "GET /api/v0/webhooks" do
    let(:webhook2) do
      create(:webhook_endpoint, user: user, target_url: "https://api.example.com/webhook")
    end

    context "when accessing via cookie" do
      before do
        sign_in user
        create(:webhook_endpoint)
      end

      it "returns 200 on success" do
        get api_webhooks_path
        expect(response).to have_http_status(:ok)
      end

      it "returns json on success" do
        webhook2
        get api_webhooks_path

        expect(response.parsed_body).to include(
          hash_including("id" => webhook.id, "target_url" => webhook.target_url),
          hash_including("id" => webhook2.id, "target_url" => webhook2.target_url),
        )
      end

      it "returns the correct json representation" do
        get api_webhooks_path

        expect(response.parsed_body.first).to eq(
          "created_at" => webhook.created_at.rfc3339,
          "events" => webhook.events,
          "id" => webhook.id,
          "source" => webhook.source,
          "target_url" => webhook.target_url,
          "type_of" => "webhook_endpoint",
        )
      end
    end
  end

  describe "GET /api/v0/webhooks/:id" do
    before do
      sign_in user
    end

    it "returns 200 on success" do
      get api_webhook_path(webhook.id)

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 if the webhook does not exist" do
      get api_webhook_path(9999)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if another user webhook is accessed" do
      other_webhook = create(:webhook_endpoint, user: create(:user))

      get api_webhook_path(other_webhook.id)

      expect(response).to have_http_status(:not_found)
    end

    it "returns the correct json representation" do
      get api_webhook_path(webhook.id)

      expect(response.parsed_body).to include(
        "created_at" => webhook.created_at.rfc3339,
        "events" => webhook.events,
        "id" => webhook.id,
        "source" => webhook.source,
        "target_url" => webhook.target_url,
        "type_of" => "webhook_endpoint",
      )
    end

    it "returns the correct json representation for the webhook user" do
      get api_webhook_path(webhook.id)

      response_webhook_user = response.parsed_body["user"]

      expect(response_webhook_user).to eq({
                                            "name" => webhook.user.name,
                                            "username" => webhook.user.username,
                                            "twitter_username" => webhook.user.twitter_username,
                                            "github_username" => webhook.user.github_username,
                                            "website_url" => webhook.user.processed_website_url,
                                            "profile_image" => Images::Profile.call(webhook.user.profile_image_url,
                                                                                    length: 640),
                                            "profile_image_90" => Images::Profile.call(webhook.user.profile_image_url,
                                                                                       length: 90)
                                          })
    end
  end

  describe "POST /api/v0/webhooks" do
    let(:webhook_params) do
      {
        source: "stackbit",
        target_url: Faker::Internet.url(scheme: "https"),
        events: %w[article_created article_updated article_destroyed]
      }
    end

    before do
      sign_in user
    end

    it "creates a webhook" do
      expect do
        post api_webhooks_path, params: { webhook_endpoint: webhook_params }
      end.to change(Webhook::Endpoint, :count).by(1)
    end

    it "creates a webhook with events and data" do
      post api_webhooks_path, params: { webhook_endpoint: webhook_params }
      created_webhook = user.webhook_endpoints.last
      expect(created_webhook.events).to eq(%w[article_created article_updated article_destroyed])
      expect(created_webhook.target_url).to eq(webhook_params[:target_url])
      expect(created_webhook.source).to eq(webhook_params[:source])
      expect(created_webhook.oauth_application_id).to eq(nil)
    end

    it "returns :created and json response on success" do
      post api_webhooks_path, params: { webhook_endpoint: webhook_params }
      expect(response).to have_http_status(:created)
      expect(response.media_type).to eq("application/json")
      json = JSON.parse(response.body)
      expect(json["target_url"]).to eq(webhook_params[:target_url])
    end
  end

  describe "DELETE /api/v0/webhooks/:id" do
    before do
      sign_in user
    end

    it "deletes the webhook" do
      expect do
        delete api_webhook_path(webhook.id)
      end.to change(Webhook::Endpoint, :count).by(-1)
    end

    it "returns 204 on success" do
      delete api_webhook_path(webhook.id)
      expect(response).to have_http_status(:no_content)
    end

    it "doesn't allow to destroy other user webhook" do
      other_webhook = create(:webhook_endpoint, user: create(:user))
      expect do
        delete api_webhook_path(other_webhook.id)
      end.not_to change(Webhook::Endpoint, :count)
    end

    it "returns 404 if another user webhook is accessed" do
      other_webhook = create(:webhook_endpoint, user: create(:user))
      delete api_webhook_path(other_webhook.id)
      expect(response).to have_http_status(:not_found)
    end
  end
end
