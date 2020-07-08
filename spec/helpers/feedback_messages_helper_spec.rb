require "rails_helper"

RSpec.describe FeedbackMessagesHelper, type: :helper do
  describe "#offender_email_details" do
    it "have proper subject and body" do
      expect(helper.offender_email_details).to include(
        subject: "#{ApplicationConfig['COMMUNITY_NAME']} Code of Conduct Violation",
        body: a_string_starting_with("Hello"),
      )
    end
  end

  describe "#reporter_email_details" do
    it "have proper subject and body" do
      expect(helper.reporter_email_details).to include(
        subject: "#{ApplicationConfig['COMMUNITY_NAME']} Report",
        body: a_string_starting_with("Hi"),
      )
    end
  end

  describe "#affected_email_details" do
    it "have proper subject and body" do
      expect(helper.affected_email_details).to include(
        subject: "Courtesy Notice from #{ApplicationConfig['COMMUNITY_NAME']}",
        body: a_string_starting_with("Hi"),
      )
    end
  end
end
