require "rails_helper"

RSpec.describe "BlockedEmailDomain Integration", type: :model do
  describe "Settings::Authentication.acceptable_domain?" do
    it "blocks domains from both the old setting and the new model" do
      # Set up old setting
      Settings::Authentication.blocked_registration_email_domains = ["oldblocked.com"]

      # Set up new model
      BlockedEmailDomain.create!(domain: "newblocked.com")

      # Test old setting still works
      expect(Settings::Authentication.acceptable_domain?(domain: "oldblocked.com")).to be false
      expect(Settings::Authentication.acceptable_domain?(domain: "sub.oldblocked.com")).to be false

      # Test new model works
      expect(Settings::Authentication.acceptable_domain?(domain: "newblocked.com")).to be false
      expect(Settings::Authentication.acceptable_domain?(domain: "sub.newblocked.com")).to be false

      # Test that both work together
      expect(Settings::Authentication.acceptable_domain?(domain: "allowed.com")).to be true
    end
  end
end
