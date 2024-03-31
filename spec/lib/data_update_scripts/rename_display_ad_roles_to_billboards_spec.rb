require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20230828081018_rename_display_ad_roles_to_billboards.rb",
)

describe DataUpdateScripts::RenameDisplayAdRolesToBillboards do
  it "updates role" do
    role = build(:role, resource_type: "DisplayAd")
    role.save(validate: false)
    described_class.new.run
    role.reload
    expect(role.resource_type).to eq("Billboard")
  end
end
