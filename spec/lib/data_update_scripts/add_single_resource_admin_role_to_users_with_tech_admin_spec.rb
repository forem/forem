require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210203104631_add_single_resource_admin_role_to_users_with_tech_admin.rb",
)

describe DataUpdateScripts::AddSingleResourceAdminRoleToUsersWithTechAdmin do
  let!(:tech_admin1) { create(:user, :tech_admin) }
  let!(:tech_admin2) { create(:user, :tech_admin) }
  let!(:admin) { create(:user, :admin) }

  it "adds single_resource_admin roles to users with tech_admin roles" do
    described_class.new.run

    expect(tech_admin1.reload.roles.pluck(:name)).to include("single_resource_admin")
    expect(tech_admin2.reload.roles.pluck(:name)).to include("single_resource_admin")
  end

  it "sets the correct resource type for the single_resource_admin role" do
    described_class.new.run
    expect(tech_admin2.reload.roles.pluck(:resource_type)).to include("DataUpdateScript")
  end

  it "does not add single_resource_admin roles alongside other roles" do
    described_class.new.run
    expect(admin.reload.roles.pluck(:name)).not_to include("single_resource_admin")
  end

end
