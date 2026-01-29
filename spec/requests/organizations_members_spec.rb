require "rails_helper"

RSpec.describe "Organizations Members" do
  let(:organization) { create(:organization) }
  let(:active_user1) { create(:user) }
  let(:active_user2) { create(:user) }
  let(:pending_user) { create(:user) }

  before do
    create(:organization_membership, user: active_user1, organization: organization, type_of_user: "admin")
    create(:organization_membership, user: active_user2, organization: organization, type_of_user: "member")
    create(:organization_membership, user: pending_user, organization: organization, type_of_user: "pending")
  end

  describe "GET /:slug/members" do
    it "returns only active members (excludes pending)" do
      get organization_members_path(slug: organization.slug)
      expect(response).to have_http_status(:success)

      members = assigns(:members)
      expect(members.count).to eq(2)
      expect(members.pluck(:id)).to contain_exactly(active_user1.id, active_user2.id)
      expect(members.pluck(:id)).not_to include(pending_user.id)
    end

    it "returns JSON with only active members" do
      get organization_members_path(slug: organization.slug), as: :json
      expect(response).to have_http_status(:success)

      json = response.parsed_body
      expect(json.count).to eq(2)
      user_ids = json.map { |u| u["id"] }
      expect(user_ids).to contain_exactly(active_user1.id, active_user2.id)
      expect(user_ids).not_to include(pending_user.id)
    end
  end
end

