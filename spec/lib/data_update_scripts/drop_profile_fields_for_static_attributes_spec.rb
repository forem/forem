require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210630063635_drop_profile_fields_for_static_attributes.rb",
)

describe DataUpdateScripts::DropProfileFieldsForStaticAttributes do
  let(:a_group) { create(:profile_field_group) }

  it "removes the 3 static profile fields" do
    %w[location summary website_url].each do |attribute|
      ProfileField.find_or_create_by(attribute_name: attribute, label: attribute, profile_field_group: a_group)
    end

    expect { described_class.new.run }.to change(ProfileField, :count).by(-3)
  end
end
