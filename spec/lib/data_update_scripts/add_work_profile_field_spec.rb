require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210630034523_add_work_profile_field.rb",
)

describe DataUpdateScripts::AddWorkProfileField do
  before { ProfileField.destroy_by(label: "Work") }

  it "adds a new profile field" do
    expect { described_class.new.run }.to change(ProfileField, :count).by(1)
  end
end
