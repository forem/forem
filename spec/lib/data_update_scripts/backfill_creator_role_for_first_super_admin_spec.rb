require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210824202334_backfill_creator_role_for_first_super_admin",
)

describe DataUpdateScripts::BackfillCreatorRoleForFirstSuperAdmin do
  let!(:creator) { create(:user, :super_admin) }
  let!(:admin) { create(:user, :super_admin) }

  it "Only the first super admin should have the creator role" do
    described_class.new.run
    expect(creator).to have_role(:creator)
    expect(admin).not_to have_role(:creator)
  end
end
