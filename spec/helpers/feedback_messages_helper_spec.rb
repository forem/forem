require "rails_helper"

RSpec.describe FeedbackMessagesHelper, type: :helper do
  describe "#offender_email_details" do
    it "has the proper subject and body" do
      expect(helper.offender_email_details).to include(
        subject: "#{SiteConfig.community_name} Code of Conduct Violation",
        body: a_string_starting_with("Hello"),
      )
    end
  end

  describe "#reporter_email_details" do
    it "has the proper subject and body" do
      expect(helper.reporter_email_details).to include(
        subject: "#{SiteConfig.community_name} Report",
        body: a_string_starting_with("Hi"),
      )
    end
  end

  describe "#affected_email_details" do
    it "has the proper subject and body" do
      expect(helper.affected_email_details).to include(
        subject: "Courtesy Notice from #{SiteConfig.community_name}",
        body: a_string_starting_with("Hi"),
      )
    end
  end
end
