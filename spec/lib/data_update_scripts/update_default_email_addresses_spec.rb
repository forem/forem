require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201218080343_update_default_email_addresses.rb",
)

describe DataUpdateScripts::UpdateDefaultEmailAddresses do
  let(:contact_email) { "contact@dev.to" }

  context "with no contact email set in the email_addresses hash" do
    it "adds the contact email" do
      described_class.new.run
      expect(SiteConfig.email_addresses).to include(contact: ApplicationConfig["DEFAULT_EMAIL"])
    end
  end

  context "with a contact email set in the email_addresses hash" do
    it "preserves the current contact email" do
      SiteConfig.email_addresses[:contact] = contact_email
      described_class.new.run
      expect(SiteConfig.email_addresses).to include(contact: contact_email)
    end
  end
end
