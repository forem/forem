require "rails_helper"

describe Admin::UsersHelper do
  describe "#role_options" do
    let(:user) { create(:user) }

    it "returns base roles as statuses", :aggregate_failures do
      user.add_role(:admin)
      roles = helper.role_options(user)
      expect(roles).to have_key("Statuses")
      expect(roles["Statuses"]).to eq Constants::Role::BASE_ROLES
    end

    it "returns special roles as roles", :aggregate_failures do
      user.add_role(:super_admin)
      roles = helper.role_options(user)
      expect(roles).to have_key("Roles")
      expect(roles["Roles"]).to eq Constants::Role::SPECIAL_ROLES
    end

    it "adds moderator role when feature flag enabled", :aggregate_failures do
      user.add_role(:super_admin)
      allow(FeatureFlag).to receive(:enabled?).with(:moderator_role).and_return(true)

      roles = helper.role_options(user)
      expect(roles).to have_key("Roles")
      expect(roles["Roles"]).to include "Super Moderator"
    end
  end

  describe "#format_last_activity_timestamp" do
    it "renders the proper 'Last activity' date for a user that was active today" do
      timestamp = Time.zone.today
      date = timestamp.strftime("%d %b")
      formatted_date = helper.format_last_activity_timestamp(timestamp)
      expect(formatted_date).to eq "Today, #{date}"
    end

    it "renders the proper 'Last activity' date for a user that was active yesterday" do
      timestamp = Date.yesterday
      date = timestamp.strftime("%d %b")
      formatted_date = helper.format_last_activity_timestamp(timestamp)
      expect(formatted_date).to eq "Yesterday, #{date}"
    end

    it "renders the proper 'Last activity' date for a user that was active recently" do
      timestamp = 11.days.ago
      date = timestamp.strftime("%d %b, %Y")
      formatted_date = helper.format_last_activity_timestamp(timestamp)
      expect(formatted_date).to eq date.to_s
    end
  end

  describe "#cascading_high_level_roles" do
    let(:user) { create(:user) }

    it "renders the proper role for a Super Admin" do
      user.add_role(:super_admin)
      role = helper.cascading_high_level_roles(user)
      expect(role).to eq "Super Admin"
    end

    it "renders the proper role for an Admin" do
      user.add_role(:admin)
      role = helper.cascading_high_level_roles(user)
      expect(role).to eq "Admin"
    end

    it "renders the proper role for a Resource Admin" do
      user.add_role(:single_resource_admin, Article)
      role = helper.cascading_high_level_roles(user)
      expect(role).to eq "Resource Admin"
    end

    it "renders the proper role for a user that isn't a Super Admin, Admin, or Resource Admin" do
      user = create(:user)
      role = helper.cascading_high_level_roles(user)
      expect(role).to be_nil
    end
  end

  describe "#format_role_tooltip" do
    let(:user) { create(:user) }

    it "renders the proper tooltip for a Super Admin" do
      user.add_role(:super_admin)
      role = helper.format_role_tooltip(user)
      expect(role).to eq "Super Admin"
    end

    it "renders the proper tooltip for an Admin" do
      user.add_role(:admin)
      role = helper.format_role_tooltip(user)
      expect(role).to eq "Admin"
    end

    it "renders the proper tooltip for a Resource Admin" do
      user.add_role(:single_resource_admin, Article)
      role = helper.format_role_tooltip(user)
      expect(role).to eq "Resource Admin: Article"
    end

    it "renders the proper, comma-separated tooltip for a Resource Admin with multiple resource_types" do
      user.add_role(:single_resource_admin, Article)
      user.add_role(:single_resource_admin, Badge)
      role = helper.format_role_tooltip(user)
      expect(role).to eq "Resource Admin: Article, Badge"
    end

    it "does not render a the resource_type for a Trusted user" do
      user.add_role(:trusted)
      role = helper.format_role_tooltip(user)
      expect(role).to be_nil
    end
  end

  describe "#user_status" do
    it "renders the proper status for a user that is suspended" do
      suspended_user = create(:user, :suspended)
      status = helper.user_status(suspended_user)
      expect(status).to eq "Suspended"
    end

    it "renders the proper status for a user that is warned" do
      warned_user = create(:user, :warned)
      status = helper.user_status(warned_user)
      expect(status).to eq "Warned"
    end

    it "renders the proper status for a user that is comment suspended" do
      comment_suspended_user = create(:user, :comment_suspended)
      status = helper.user_status(comment_suspended_user)
      expect(status).to eq "Comment Suspended"
    end

    it "renders the proper status for a user that is trusted" do
      trusted_user = create(:user, :trusted)
      status = helper.user_status(trusted_user)
      expect(status).to eq "Trusted"
    end

    it "renders the proper status for a user that is good standing" do
      good_standing_user = create(:user)
      status = helper.user_status(good_standing_user)
      expect(status).to eq "Good Standing"
    end
  end

  describe "#overflow_count" do
    it "renders an overflow count" do
      overflow = helper.overflow_count(5, imposed_limit: 4)
      expect(overflow).to eq 1
    end

    it "renders nothing if the imposed limit is less than the count" do
      overflow = helper.overflow_count(1, imposed_limit: 4)
      expect(overflow).to be_nil
    end
  end

  describe "#organization_tooltip" do
    context "when the limit is less than the total" do
      it "renders the correct tooltip when the array of items do not match the imposed limit" do
        tooltip = helper.organization_tooltip(%w[org1 org2 org3], 3, imposed_limit: 2)
        expect(tooltip).to eq "org1, org2 & 1 other"
      end

      it "renders the correct tooltip for an overflow of 1" do
        tooltip = helper.organization_tooltip(%w[org1 org2], 3, imposed_limit: 2)
        expect(tooltip).to eq "org1, org2 & 1 other"
      end

      it "renders the correct tooltip for an overflow of more than 1" do
        tooltip = helper.organization_tooltip(%w[org1 org2], 4, imposed_limit: 2)
        expect(tooltip).to eq "org1, org2 & 2 others"
      end
    end

    context "when the limit is more than the total" do
      it "renders the correct tooltip" do
        tooltip = helper.organization_tooltip(%w[org1], 1, imposed_limit: 2)
        expect(tooltip).to eq "org1"
      end
    end
  end
end
