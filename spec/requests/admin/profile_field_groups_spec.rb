require "rails_helper"

RSpec.describe "/admin/customization/profile_field_groups", type: :request do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
    allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(true)
  end

  describe "POST /admin/customization/profile_field_groups" do
    let(:new_profile_field_group) do
      {
        name: "Group 1",
        description: "Description"
      }
    end

    it "redirects successfully" do
      post admin_profile_field_groups_path, params: { profile_field_group: new_profile_field_group }
      expect(response).to redirect_to admin_profile_fields_path
    end

    it "creates a profile_field_group" do
      expect do
        post admin_profile_field_groups_path, params: { profile_field_group: new_profile_field_group }
      end.to change { ProfileFieldGroup.all.count }.by(1)

      last_profile_field_record = ProfileFieldGroup.last
      expect(last_profile_field_record.name).to eq(new_profile_field_group[:name])
      expect(last_profile_field_record.description).to eq(new_profile_field_group[:description])
    end
  end

  describe "PUT /admin/customization/profile_field_groups/:id" do
    let(:profile_field_group) { create(:profile_field_group) }

    it "redirects successfully" do
      put "#{admin_profile_field_groups_path}/#{profile_field_group.id}",
          params: { profile_field_group: { name: "Group 2" } }
      expect(response).to redirect_to admin_profile_fields_path
    end

    it "updates the profile field values" do
      put "#{admin_profile_field_groups_path}/#{profile_field_group.id}",
          params: { profile_field_group: { name: "Group 2" } }

      changed_profile_group_record = ProfileFieldGroup.find(profile_field_group.id)
      expect(changed_profile_group_record.name).to eq("Group 2")
    end
  end

  describe "DELETE /admin/profile_fields/:id" do
    let!(:profile_field_group) { create(:profile_field_group) }

    it "redirects successfully" do
      delete "#{admin_profile_field_groups_path}/#{profile_field_group.id}"
      expect(response).to redirect_to admin_profile_fields_path
    end

    it "removes a profile_field_group" do
      expect do
        delete "#{admin_profile_field_groups_path}/#{profile_field_group.id}"
      end.to change(ProfileFieldGroup, :count).by(-1)
    end
  end
end
