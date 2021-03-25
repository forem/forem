require "rails_helper"

RSpec.describe "/admin/profile_fields", type: :request do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
    allow(FeatureFlag).to receive(:enabled?).and_call_original
    allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(true)
  end

  describe "GET /admin/profile_fields" do
    it "renders successfully" do
      get admin_profile_fields_path
      expect(response).to be_successful
    end

    it "lists the profile fields" do
      profile_field = create(:profile_field)
      get admin_profile_fields_path
      expect(response.body).to include(
        profile_field.label,
        profile_field.input_type,
        profile_field.description,
        profile_field.placeholder_text,
      )
    end
  end

  describe "POST /admin/profile_fields" do
    let(:new_profile_field) do
      {
        label: "Test Location",
        input_type: "text_field",
        description: "users' location",
        placeholder_text: "new york"
      }
    end

    it "redirects successfully" do
      post admin_profile_fields_path, params: { profile_field: new_profile_field }
      expect(response).to redirect_to admin_profile_fields_path
    end

    it "creates a profile_field" do
      expect do
        post admin_profile_fields_path, params: { profile_field: new_profile_field }
      end.to change { ProfileField.all.count }.by(1)

      last_profile_field_record = ProfileField.last
      expect(last_profile_field_record.label).to eq(new_profile_field[:label])
      expect(last_profile_field_record.input_type).to eq(new_profile_field[:input_type])
      expect(last_profile_field_record.description).to eq(new_profile_field[:description])
      expect(last_profile_field_record.placeholder_text).to eq(new_profile_field[:placeholder_text])
    end
  end

  describe "PUT /admin/profile_fields/:id" do
    let(:profile_field) { create(:profile_field) }

    it "redirects successfully" do
      put "#{admin_profile_fields_path}/#{profile_field.id}",
          params: { profile_field: { show_in_onboarding: false } }
      expect(response).to redirect_to admin_profile_fields_path
    end

    it "updates the profile field values" do
      put "#{admin_profile_fields_path}/#{profile_field.id}",
          params: { profile_field: { show_in_onboarding: false } }

      changed_profile_record = ProfileField.find(profile_field.id)
      expect(changed_profile_record.show_in_onboarding).to be(false)
    end
  end

  describe "DELETE /admin/profile_fields/:id" do
    let!(:profile_field) do
      create(:profile_field).tap { Profile.refresh_attributes! }
    end

    it "redirects successfully" do
      delete "#{admin_profile_fields_path}/#{profile_field.id}"
      expect(response).to redirect_to admin_profile_fields_path
    end

    it "removes a profile field" do
      expect do
        delete "#{admin_profile_fields_path}/#{profile_field.id}"
      end.to change(ProfileField, :count).by(-1)
    end
  end
end
