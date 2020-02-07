require "rails_helper"

RSpec.describe "Api::V0::Webhooks", type: :request do
  let_it_be_changeable(:user) { create(:user) }
  let_it_be_changeable(:webhook) do
    create(:webhook_endpoint, user: user, target_url: "https://api.example.com/go")
  end

  describe "GET /api/v0/webhooks" do
    let_it_be_readonly(:webhook2) do
      create(:webhook_endpoint, user: user, target_url: "https://api.example.com/webhook")
    end

    before do
      sign_in user
      create(:webhook_endpoint)
    end

    it "returns 200 on success" do
      get api_webhooks_path
      expect(response).to have_http_status(:ok)
    end

    it "returns json on success" do
      get api_webhooks_path

      json = response.parsed_body
      ids = json.map { |item| item["id"] }
      urls = json.map { |item| item["target_url"] }
      expect(ids).to eq([webhook.id, webhook2.id])
      expect(urls).to eq(%w[https://api.example.com/go https://api.example.com/webhook])
    end

    it "returns the correct json representation" do
      get api_webhooks_path

      response_webhook = response.parsed_body.first

      expect(response_webhook["type_of"]).to eq("webhook_endpoint")
      expect(response_webhook["id"]).to eq(webhook.id)
      expect(response_webhook["source"]).to eq(webhook.source)
      expect(response_webhook["target_url"]).to eq(webhook.target_url)
      expect(response_webhook["events"]).to eq(webhook.events)
      expect(response_webhook["created_at"]).to eq(webhook.created_at.rfc3339)
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

      response_webhook = response.parsed_body

      expect(response_webhook["type_of"]).to eq("webhook_endpoint")
      expect(response_webhook["id"]).to eq(webhook.id)
      expect(response_webhook["source"]).to eq(webhook.source)
      expect(response_webhook["target_url"]).to eq(webhook.target_url)
      expect(response_webhook["events"]).to eq(webhook.events)
      expect(response_webhook["created_at"]).to eq(webhook.created_at.rfc3339)
    end

    it "returns the correct json representation for the webhook user" do
      get api_webhook_path(webhook.id)

      response_webhook_user = response.parsed_body["user"]
      user_profile_image = ProfileImage.new(webhook.user)

      expect(response_webhook_user["name"]).to eq(webhook.user.name)
      expect(response_webhook_user["username"]).to eq(webhook.user.username)
      expect(response_webhook_user["twitter_username"]).to eq(webhook.user.twitter_username)
      expect(response_webhook_user["github_username"]).to eq(webhook.user.github_username)
      expect(response_webhook_user["website_url"]).to eq(webhook.user.processed_website_url)
      expect(response_webhook_user["profile_image"]).to eq(user_profile_image.get(width: 640))
      expect(response_webhook_user["profile_image_90"]).to eq(user_profile_image.get(width: 90))
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
      expect(response.content_type).to eq("application/json")
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

  describe "authorized with doorkeeper" do
    let!(:oauth_app) { create(:application) }
    let!(:oauth_app2) { create(:application) }
    let(:access_token) { create :doorkeeper_access_token, resource_owner: user, application: oauth_app2, scopes: "public" }

    it "renders index successfully" do
      get api_webhooks_path, params: { access_token: access_token.token }
      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "renders only corresponding webhooks" do
      create(:webhook_endpoint, oauth_application_id: oauth_app.id, user: user)
      webhook2 = create(:webhook_endpoint, oauth_application_id: oauth_app2.id, user: user)
      get api_webhooks_path, params: { access_token: access_token.token }

      json = JSON.parse(response.body)
      ids = json.map { |item| item["id"] }
      expect(ids).to eq([webhook2.id])
    end

    it "sets correct oauth app id for the webhook if needed" do
      webhook_params = {
        source: "stackbit",
        target_url: Faker::Internet.url(scheme: "https"),
        events: %w[article_created article_updated article_destroyed]
      }
      post api_webhooks_path, params: { access_token: access_token.token, webhook_endpoint: webhook_params }
      webhook = user.webhook_endpoints.find_by(target_url: webhook_params[:target_url])
      expect(webhook.oauth_application_id).to eq(oauth_app2.id)
    end

    it "doesn't allow destroying another app webhook" do
      other_webhook = create(:webhook_endpoint, user: user)
      delete api_webhook_path(other_webhook.id), params: { access_token: access_token.token }
      expect(response).to have_http_status(:not_found)
    end
  end
end
