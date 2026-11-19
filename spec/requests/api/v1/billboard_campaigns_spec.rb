require "rails_helper"

RSpec.describe "Api::V1::BillboardCampaigns" do
  let(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:api_secret) { create(:api_secret) }
  let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
  let(:campaign_params) do
    { name: "CodeNewbie S28", expires_at: 2.weeks.from_now.iso8601, max_impressions_count: 50_000 }
  end

  context "when the user is an admin" do
    before do
      api_secret.user.add_role(:admin)
      Audit::Subscribe.listen :admin_api
    end

    after { Audit::Subscribe.forget :admin_api }

    it "creates a campaign and logs it" do
      expect do
        post api_billboard_campaigns_path, params: campaign_params.to_json, headers: auth_header
      end.to change(BillboardCampaign, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("name" => "CodeNewbie S28", "max_impressions_count" => 50_000)
      expect(AuditLog.last).to have_attributes(slug: "api_billboard_campaign_create",
                                               data: include("billboard_campaign_id" => BillboardCampaign.last.id))
    end

    it "rejects a campaign without a name" do
      post api_billboard_campaigns_path, params: { max_clicks_count: 10 }.to_json, headers: auth_header
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "updates a campaign" do
      campaign = BillboardCampaign.create!(name: "Launch")
      put api_billboard_campaign_path(campaign.id), params: { max_clicks_count: 200 }.to_json, headers: auth_header

      expect(response).to have_http_status(:ok)
      expect(campaign.reload.max_clicks_count).to eq(200)
    end

    it "lists and shows campaigns" do
      campaign = BillboardCampaign.create!(name: "Launch")
      get api_billboard_campaigns_path, headers: auth_header
      expect(response.parsed_body.pluck("id")).to eq([campaign.id])

      get api_billboard_campaign_path(campaign.id), headers: auth_header
      expect(response.parsed_body["name"]).to eq("Launch")
    end

    it "assigns a billboard to a campaign with caps" do
      campaign = BillboardCampaign.create!(name: "Launch")
      billboard = create(:billboard)
      put api_billboard_path(billboard.id),
          params: { billboard_campaign_id: campaign.id, max_impressions_count: 1_000 }.to_json,
          headers: auth_header

      expect(response).to have_http_status(:ok)
      expect(billboard.reload).to have_attributes(billboard_campaign_id: campaign.id, max_impressions_count: 1_000)
    end
  end

  context "when the user is not an admin" do
    it "refuses access" do
      post api_billboard_campaigns_path, params: campaign_params.to_json, headers: auth_header
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
