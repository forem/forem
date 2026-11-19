require "rails_helper"

RSpec.describe Admin::PermissionsHelper do
  describe "#grantable_role_options_grouped" do
    it "groups platform and resource roles and hides super-admin-only resources for regular admins",
       :aggregate_failures do
      grouped = helper.grantable_role_options_grouped(is_super_admin: false)
      platform_values = grouped.first.last.map(&:last)
      resource_values = grouped.last.last.map(&:last)

      expect(platform_values).to eq(%w[super_admin admin tech_admin])
      expect(resource_values).to include("single_resource_admin|Billboard", "single_resource_admin|Article")
      expect(resource_values).not_to include("single_resource_admin|OrganizationPageManagement")
      expect(platform_values + resource_values).not_to include("community_leader_level_1", "community_leader_level_2")
    end

    it "includes super-admin-only resources for super admins and marks configurable resources", :aggregate_failures do
      grouped = helper.grantable_role_options_grouped(is_super_admin: true)
      resource_entries = grouped.last.last

      expect(resource_entries.map(&:last)).to include("single_resource_admin|OrganizationPageManagement")
      billboard_entry = resource_entries.detect { |_label, value| value == "single_resource_admin|Billboard" }
      expect(billboard_entry.first).to include("Billboard Admin")
      expect(billboard_entry.first).to include("sub-permissions")
    end
  end

  describe "#assignable_role_options_for_user" do
    it "excludes roles the user already holds" do
      user = create(:user, :admin)
      user.add_role(:single_resource_admin, Billboard)

      values = helper.assignable_role_options_for_user(user.reload, is_super_admin: true)
        .flat_map { |_group, options| options.map(&:last) }

      expect(values).not_to include("admin", "single_resource_admin|Billboard")
      expect(values).to include("tech_admin", "single_resource_admin|Article")
    end
  end

  describe "#user_admin_roles" do
    it "lists all held admin roles in privilege order with restriction metadata", :aggregate_failures do
      user = create(:user, :admin)
      user.add_role(:tech_admin)
      user.add_role(:single_resource_admin, Billboard)
      user.add_role(:single_resource_admin, OrganizationPageManagement)

      sub_permissions = { [user.id, "Billboard"] => { "version" => 1, "allow" => %w[publish] } }
      roles = helper.user_admin_roles(user.reload, sub_permissions, is_super_admin: false)

      expect(roles.pluck(:value)).to eq(
        %w[admin tech_admin single_resource_admin|Billboard single_resource_admin|OrganizationPageManagement],
      )
      billboard_role = roles.detect { |r| r[:resource_type] == "Billboard" }
      expect(billboard_role[:restricted]).to be(true)
      expect(billboard_role[:configurable]).to be(true)
      expect(billboard_role[:can_revoke]).to be(true)

      org_page_role = roles.detect { |r| r[:resource_type] == "OrganizationPageManagement" }
      expect(org_page_role[:can_revoke]).to be(false)
    end
  end
end
