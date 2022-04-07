require "rails_helper"

describe Admin::UsersHelper do
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
    it "renders the proper role for a Super Admin" do
      super_admin = create(:user, :super_admin)
      role = helper.cascading_high_level_roles(super_admin)
      expect(role).to eq "Super Admin"
    end

    it "renders the proper role for an Admin" do
      admin = create(:user, :admin)
      role = helper.cascading_high_level_roles(admin)
      expect(role).to eq "Admin"
    end

    it "renders the proper role for a Resource Admin" do
      resource_admin = create(:user, :single_resource_admin)
      role = helper.cascading_high_level_roles(resource_admin)
      expect(role).to eq "Resource Admin"
    end

    it "renders the proper role for a user that isn't a Super Admin, Admin, or Resource Admin" do
      user = create(:user)
      role = helper.cascading_high_level_roles(user)
      expect(role).to be_nil
    end
  end
end
