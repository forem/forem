require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/customization/billboard_campaigns" do
  let(:campaign) { BillboardCampaign.create!(name: "Launch week") }

  before { Audit::Subscribe.listen :internal }
  after { Audit::Subscribe.forget :internal }

  it_behaves_like "an InternalPolicy dependant request", Billboard do
    let(:request) { get admin_billboard_campaigns_path }
  end

  context "when signed in as a super admin" do
    let(:admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }

    before { sign_in admin }

    it "lists campaign names and IDs without counting rows or loading billboards", :aggregate_failures do
      BillboardCampaign.insert_all!((1..51).map { |number| { name: "Campaign number #{number}." } })
      queries = []
      capture = lambda do |*, payload|
        queries << payload[:sql] unless payload[:cached] || payload[:name] == "SCHEMA"
      end

      ActiveSupport::Notifications.subscribed(capture, "sql.active_record") { get admin_billboard_campaigns_path }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Campaign number 51.", 'rel="next"')
      expect(response.body).not_to include("Campaign number 1.")
      expect(queries.grep(/FROM "billboard_campaigns"/i)).to contain_exactly(
        a_string_matching(/SELECT "billboard_campaigns"."id", "billboard_campaigns"."name".*LIMIT/i),
      )
      expect(queries.grep(/FROM "display_ads"/i)).to be_empty
    end

    it "opens a new campaign form" do
      get new_admin_billboard_campaign_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="billboard_campaign[max_impressions_count]"')
    end

    it "creates a campaign with shared delivery limits", :aggregate_failures do
      end_date = 3.days.from_now.change(sec: 0)
      post admin_billboard_campaigns_path, params: {
        billboard_campaign: { name: "New campaign", expires_at: end_date.iso8601, max_impressions_count: 300,
                              max_clicks_count: 10, ideal_daily_impressions: 50 }
      }

      created = BillboardCampaign.find_by!(name: "New campaign")
      expect(response).to redirect_to(edit_admin_billboard_campaign_path(created))
      expect(created).to have_attributes(expires_at: end_date, max_impressions_count: 300, max_clicks_count: 10,
                                         ideal_daily_impressions: 50)
      expect(AuditLog.last).to have_attributes(user_id: admin.id, slug: "billboard_campaign_create",
                                               data: include("billboard_campaign_id" => created.id))

      follow_redirect!
      expect(response.body).to include("Edit campaign: New campaign",
                                       'name="billboard_campaign[ideal_daily_impressions]"')
    end

    it "updates delivery limits but leaves the worker-managed throttle alone", :aggregate_failures do
      patch admin_billboard_campaign_path(campaign), params: {
        billboard_campaign: { max_clicks_count: 25, ideal_daily_impressions: 100, delivery_throttle_rate: 0.01 }
      }

      expect(response).to redirect_to(edit_admin_billboard_campaign_path(campaign))
      expect(campaign.reload).to have_attributes(max_clicks_count: 25, ideal_daily_impressions: 100,
                                                 delivery_throttle_rate: 1.0)
      expect(AuditLog.last).to have_attributes(user_id: admin.id, slug: "billboard_campaign_update",
                                               data: include("billboard_campaign_id" => campaign.id))
    end

    it "rejects an invalid cap and renders the edit form again", :aggregate_failures do
      expect do
        patch admin_billboard_campaign_path(campaign), params: { billboard_campaign: { max_clicks_count: -1 } }
      end.not_to change(AuditLog, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('name="billboard_campaign[max_clicks_count]"')
      expect(campaign.reload.max_clicks_count).to eq(0)
    end
  end

  context "when a Billboard admin has no sub-permissions" do
    let(:admin) { create(:user, :single_resource_admin, :without_profile, profile_image: nil, resource: Billboard) }

    before do
      SubPermissions.update_grant(user: admin, resource_type: "Billboard",
                                  sub_permissions: SubPermissions.build(allow: []))
      sign_in admin
    end

    it "allows changes to a draft campaign", :aggregate_failures do
      patch admin_billboard_campaign_path(campaign), params: { billboard_campaign: { max_clicks_count: 25 } }

      expect(response).to redirect_to(edit_admin_billboard_campaign_path(campaign))
      expect(campaign.reload.max_clicks_count).to eq(25)
    end

    it "refuses changes to the limits of a campaign with an approved billboard", :aggregate_failures do
      create(:billboard, billboard_campaign: campaign, approved: true, organization: nil)

      expect do
        patch admin_billboard_campaign_path(campaign), params: { billboard_campaign: { max_clicks_count: 25 } }
      end.not_to change(AuditLog, :count)

      expect(response).to have_http_status(:forbidden)
      expect(campaign.reload.max_clicks_count).to eq(0)
    end
  end
end
