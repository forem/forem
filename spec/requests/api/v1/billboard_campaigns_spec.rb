require "rails_helper"

RSpec.describe "Api::V1::BillboardCampaigns" do
  let(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:api_secret) { create(:api_secret) }
  let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
  let(:campaign_params) do
    {
      name: "CodeNewbie S28",
      expires_at: 2.weeks.from_now.iso8601,
      max_impressions_count: 50_000,
      ideal_daily_impressions: 5_000
    }
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
      expect(response.parsed_body).to include(
        "name" => "CodeNewbie S28",
        "max_impressions_count" => 50_000,
        "ideal_daily_impressions" => 5_000,
        "delivery_throttle_rate" => 1.0,
      )
      expect(AuditLog.last).to have_attributes(slug: "api_billboard_campaign_create",
                                               data: include("billboard_campaign_id" => BillboardCampaign.last.id))
    end

    it "rejects a campaign without a name" do
      post api_billboard_campaigns_path, params: { max_clicks_count: 10 }.to_json, headers: auth_header
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "updates a campaign including ideal_daily_impressions and ignores delivery_throttle_rate" do
      campaign = BillboardCampaign.create!(name: "Launch")
      put api_billboard_campaign_path(campaign.id),
          params: { max_clicks_count: 200, ideal_daily_impressions: 10_000, delivery_throttle_rate: 0.1 }.to_json,
          headers: auth_header

      expect(response).to have_http_status(:ok)
      expect(campaign.reload).to have_attributes(
        max_clicks_count: 200,
        ideal_daily_impressions: 10_000,
        delivery_throttle_rate: 1.0,
      )
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

  context "when a cap is out of range" do
    before { api_secret.user.add_role(:admin) }

    it "returns a validation error" do
      post api_billboard_campaigns_path, params: campaign_params.merge(max_clicks_count: 2**31).to_json,
                                         headers: auth_header
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when the API key's user is a Billboard admin with restricted sub-permissions" do
    let(:allowed) { [] }
    let(:campaign) { BillboardCampaign.create!(name: "Launch", max_impressions_count: 1_000) }

    before do
      api_secret.user.add_role(:single_resource_admin, Billboard)
      SubPermissions.update_grant(user: api_secret.user, resource_type: "Billboard",
                                  sub_permissions: SubPermissions.build(allow: allowed))
    end

    it "can list, read and create campaigns", :aggregate_failures do
      get api_billboard_campaigns_path, headers: auth_header
      expect(response).to have_http_status(:ok)

      get api_billboard_campaign_path(campaign.id), headers: auth_header
      expect(response).to have_http_status(:ok)

      post api_billboard_campaigns_path, params: campaign_params.to_json, headers: auth_header
      expect(response).to have_http_status(:created)
    end

    it "can change a campaign whose billboards are all unapproved" do
      create(:billboard, approved: false, billboard_campaign: campaign)
      put api_billboard_campaign_path(campaign.id), params: { max_impressions_count: 5_000 }.to_json,
                                                    headers: auth_header

      expect(response).to have_http_status(:ok)
      expect(campaign.reload.max_impressions_count).to eq(5_000)
    end

    {
      "an approved billboard" => { approved: true },
      "an Event-owned billboard" => { approved: false, event: :event }
    }.each do |description, attrs|
      it "refuses to change a campaign that governs #{description}", :aggregate_failures do
        billboard_attrs = attrs.except(:event)
        billboard_attrs[:event] = create(:event) if attrs[:event]
        create(:billboard, billboard_campaign: campaign, **billboard_attrs)

        put api_billboard_campaign_path(campaign.id),
            params: { max_impressions_count: 5_000, expires_at: 1.year.from_now.iso8601 }.to_json,
            headers: auth_header

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).to eq(
          "error" => "Your Billboard admin access does not include: " \
                     "change or delete approved billboards and Event billboards.",
          "status" => 403,
        )
        expect(campaign.reload).to have_attributes(max_impressions_count: 1_000, expires_at: nil)
      end
    end

    context "with modify_approved" do
      let(:allowed) { %w[modify_approved] }

      it "can change a campaign that governs an approved billboard" do
        create(:billboard, approved: true, billboard_campaign: campaign)
        put api_billboard_campaign_path(campaign.id), params: { max_impressions_count: 5_000 }.to_json,
                                                      headers: auth_header

        expect(response).to have_http_status(:ok)
        expect(campaign.reload.max_impressions_count).to eq(5_000)
      end
    end
  end

  describe "refusals" do
    let(:campaign) { BillboardCampaign.create!(name: "Launch") }
    let(:requests) do
      {
        index: -> { get api_billboard_campaigns_path, headers: headers },
        show: -> { get api_billboard_campaign_path(campaign.id), headers: headers },
        create: -> { post api_billboard_campaigns_path, params: campaign_params.to_json, headers: headers },
        update: lambda {
          put api_billboard_campaign_path(campaign.id), params: { name: "Changed" }.to_json, headers: headers
        }
      }
    end

    context "when the user is not an admin" do
      let(:headers) { auth_header }

      it "refuses every action", :aggregate_failures do
        requests.each_value do |request|
          request.call
          expect(response).to have_http_status(:unauthorized)
        end
        expect(campaign.reload.name).to eq("Launch")
      end
    end

    context "when the API key is missing" do
      let(:headers) { v1_headers }

      it "refuses every action", :aggregate_failures do
        requests.each_value do |request|
          request.call
          expect(response).to have_http_status(:unauthorized)
        end
        expect(campaign.reload.name).to eq("Launch")
      end
    end
  end
end
