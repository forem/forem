require "rails_helper"

RSpec.describe "Api::V0::Webhooks", type: :request do
  let(:user) { create(:user) }
  let!(:webhook) { create(:webhook_endpoint, user: user) }

  before do
    sign_in user
  end

  describe "GET /api/v0/webhooks/:id" do
    it "returns 200 on success" do
      get "/api/webhooks/#{webhook.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 if the webhook does not exist" do
      get "/api/webhooks/9999"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if another user webhook is accessed" do
      other_webhook = create(:webhook_endpoint, user: create(:user))
      get "/api/webhooks/#{other_webhook.id}"
      expect(response).to have_http_status(:not_found)
    end

    it "returns json on success" do
      get "/api/webhooks/#{webhook.id}"
      json = JSON.parse(response.body)
      expect(json["target_url"]).to eq(webhook.target_url)
      expect(json["user"]["username"]).to eq(user.username)
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

    it "creates a webhook" do
      expect do
        post "/api/webhooks", params: { webhook_endpoint: webhook_params }
      end.to change(Webhook::Endpoint, :count).by(1)
    end

    it "creates a webhook with events and data" do
      post "/api/webhooks", params: { webhook_endpoint: webhook_params }
      created_webhook = user.webhook_endpoints.last
      expect(created_webhook.events).to eq(%w[article_created article_updated article_destroyed])
      expect(created_webhook.target_url).to eq(webhook_params[:target_url])
      expect(created_webhook.source).to eq(webhook_params[:source])
    end

    it "returns :created and json response on success" do
      post "/api/webhooks", params: { webhook_endpoint: webhook_params }
      expect(response).to have_http_status(:created)
      expect(response.content_type).to eq("application/json")
      json = JSON.parse(response.body)
      expect(json["target_url"]).to eq(webhook_params[:target_url])
    end
  end

  describe "DELETE /api/v0/webhooks/:id" do
    it "deletes the webhook" do
      expect do
        delete "/api/webhooks/#{webhook.id}"
      end.to change(Webhook::Endpoint, :count).by(-1)
    end

    it "returns 204 on success" do
      delete "/api/webhooks/#{webhook.id}"
      expect(response).to have_http_status(:no_content)
    end

    it "doesn't allow to destroy other user webhook" do
      other_webhook = create(:webhook_endpoint, user: create(:user))
      expect do
        delete "/api/webhooks/#{other_webhook.id}"
      end.not_to change(Webhook::Endpoint, :count)
    end

    it "returns 404 if another user webhook is accessed" do
      other_webhook = create(:webhook_endpoint, user: create(:user))
      delete "/api/webhooks/#{other_webhook.id}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
