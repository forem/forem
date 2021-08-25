require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210824202334_backfill_forem_owner_role.rb",
)

describe DataUpdateScripts::BackfillForemOwnerRole do
  let!(:owner) { create(:user, :super_admin) }
  let!(:admin) { create(:user, :super_admin) }

  it "Only the first super admin should have the creator role" do
    described_class.new.run
    expect(owner.has_role?(:creator)).to be true
    expect(admin.has_role?(:creator)).to be false
  end
end
