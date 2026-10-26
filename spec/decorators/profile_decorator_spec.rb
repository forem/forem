require "rails_helper"

RSpec.describe ProfileDecorator do
  let(:user) { create(:user) }
  let(:profile) { user.profile }

  before { RequestStore.clear! }
  after { RequestStore.clear! }

  describe "#ui_attributes_for" do
    it "returns an empty hash without querying ProfileField when data is blank" do
      profile.update_column(:data, {})
      allow(ProfileField).to receive(:cached_display_area_fields)

      expect(profile.decorate.ui_attributes_for(area: :header)).to eq({})
      expect(ProfileField).not_to have_received(:cached_display_area_fields)
    end

    it "returns non-blank profile attributes for the requested display area" do
      field = create(:profile_field, label: "Current Role", display_area: :left_sidebar)
      profile.update_column(:data, { field.attribute_name => "Staff Engineer" })

      expect(profile.decorate.ui_attributes_for(area: :left_sidebar)).to eq("Current Role" => "Staff Engineer")
    end
  end
end
