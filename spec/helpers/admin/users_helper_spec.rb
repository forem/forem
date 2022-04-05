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
end
