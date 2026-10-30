require "rails_helper"

RSpec.describe "ProfileFieldGroups" do
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

    context "when onboarding has not been completed" do
      let(:user) do
        create(:user, saw_onboarding: false, checked_code_of_conduct: false, checked_terms_and_conditions: false)
      end

      it "marks onboarding and both agreements as completed", :aggregate_failures do
        get profile_field_groups_path, params: { onboarding: true }

        expect(response).to have_http_status(:ok)
        expect(user.reload).to have_attributes(
          saw_onboarding: true,
          checked_code_of_conduct: true,
          checked_terms_and_conditions: true,
        )
      end

      it "does not mark onboarding or agreements as completed for a regular request" do
        get profile_field_groups_path

        expect(user.reload).to have_attributes(
          saw_onboarding: false,
          checked_code_of_conduct: false,
          checked_terms_and_conditions: false,
        )
      end
    end

    context "when signed out" do
      before { sign_out user }

      it "returns all profile field groups", :aggregate_failures do
        get profile_field_groups_path

        expect(response).to have_http_status(:ok)
        groups = JSON.parse(response.body, symbolize_names: true)[:profile_field_groups]
        expect(groups).to match_array(ProfileFieldGroup.ids.map { |id| include(id: id) })
      end

      it "returns onboarding fields without attempting to update a user", :aggregate_failures do
        get profile_field_groups_path, params: { onboarding: true }

        expect(response).to have_http_status(:ok)
        groups = JSON.parse(response.body, symbolize_names: true)[:profile_field_groups]
        expect(groups).to contain_exactly(include(id: group1.id))
        expect(groups.first[:profile_fields]).to contain_exactly(
          include(id: ProfileField.find_by!(label: "Field 1").id),
        )
      end
    end
  end
end
