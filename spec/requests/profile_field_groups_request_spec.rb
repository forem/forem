require "rails_helper"

RSpec.describe "ProfileFieldGroups", type: :request do
  let(:user) { create(:user) }

  describe "GET /profile_field_groups" do
    let!(:group1) { create(:profile_field_group) }
    let!(:group2) { create(:profile_field_group) }

    before do
      create(:profile_field, :onboarding, label: "Field 1", profile_field_group: group1)
      create(:profile_field, label: "Field 2", profile_field_group: group1)
      create(:profile_field, label: "Field 3", profile_field_group: group2)
      Profile.refresh_attributes!

      sign_in user
    end

    it "returns a successful response" do
      get profile_field_groups_path
      expect(response).to have_http_status :ok
    end

    it "returns all groups with all fields by default" do
      get profile_field_groups_path
      json_response = JSON.parse(response.body, symbolize_names: true)
      expect(json_response[:profile_field_groups].size).to eq ProfileFieldGroup.all.size
    end

    it "returns only groups with onboarding fields when onboarding=true", :aggregate_failures do
      get profile_field_groups_path, params: { onboarding: true }
      json_response = JSON.parse(response.body, symbolize_names: true)
      groups = json_response[:profile_field_groups]
      expect(groups.any? { |g| g[:name] == group1.name }).to be true
      expect(groups.any? { |g| g[:name] == group2.name }).to be false
    end

    it "only returns the onboarding fields in the group", :aggregate_failures do
      get profile_field_groups_path, params: { onboarding: true }
      json_response = JSON.parse(response.body, symbolize_names: true)
      groups = json_response[:profile_field_groups]
      group = groups.detect { |g| g[:name] == group1.name }
      expect(group[:profile_fields].size).to eq 1
      field1 = ProfileField.find_by(label: "Field 1")
      expect(group[:profile_fields].first[:id]).to eq field1.id
    end
  end
end
