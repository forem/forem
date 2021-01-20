require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201208151516_set_onboarding_profile_fields_for_existing_forems.rb",
)

describe DataUpdateScripts::SetOnboardingProfileFieldsForExistingForems do
  before do
    ProfileField.destroy_all
    create(:user)
  end

  let!(:profile_field1) { create(:profile_field, label: "summary") }
  let!(:profile_field2) { create(:profile_field, label: "random") }
  let(:profile_field3) { create(:profile_field, label: "location") }

  it "toggles show_in_onboarding to true for specific profile fields" do
    expect do
      described_class.new.run
    end.to change { profile_field1.reload.show_in_onboarding }.from(false).to(true)
    expect(profile_field2.reload.show_in_onboarding).to be false
  end

  it "updates the labels for specific profile fields" do
    # NOTE: we update the label manually here because when
    # we create the profile field the attribute_name is a
    # underscored version of the label.
    profile_field3.update(label: "Where are you located?")
    described_class.new.run
    expect(profile_field3.reload.label).to eq("Location")
  end
end
