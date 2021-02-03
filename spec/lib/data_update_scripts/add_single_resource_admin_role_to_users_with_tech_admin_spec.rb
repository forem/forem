require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210203104631_add_single_resource_admin_role_to_users_with_tech_admin.rb",
)

describe DataUpdateScripts::AddSingleResourceAdminRoleToUsersWithTechAdmin do

  before do
    users = create_list(:user, 5)
    User.first.add_role(:tech_admin)
    User.second.add_role(:admin)
    User.last.add_role(:tech_admin)
  end

  it "adds single_resource_admin roles to users with tech_admin roles" do
    described_class.new.run

    expect(User.first.roles.pluck(:name)).to include("single_resource_admin")
    expect(User.last.roles.pluck(:name)).to include("single_resource_admin")
  end

  it "sets the correct resource type for the single_resource_admin role" do
    described_class.new.run
    expect(User.last.roles.pluck(:resource_type)).to include("DataUpdateScript")
  end

  it "does not add single_resource_admin roles alongside other roles" do
    described_class.new.run
    expect(User.second.roles.pluck(:name)).not_to include("single_resource_admin")
  end

end
