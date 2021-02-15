require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210209185037_add_single_resource_role_to_tech_admins.rb",
)

describe DataUpdateScripts::AddSingleResourceRoleToTechAdmins do
  let!(:admin) { create(:user, :admin) }

  context "without any tech_admin users" do
    it "does not add any roles to any other users with roles" do
      expect do
        described_class.new.run
      end.not_to change(admin.reload.roles, :count)
    end
  end

  context "with tech_admin users" do
    let!(:tech_admin1) { create(:user, :tech_admin) }
    let!(:tech_admin2) { create(:user, :tech_admin) }

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
end
