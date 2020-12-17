require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201210163704_set_contact_email_address.rb",
)

describe DataUpdateScripts::SetContactEmailAddress do
  let(:contact_email) { "contact@dev.to" }

  before do
    allow(SiteConfig).to receive(:email_addresses).and_return(
      {
        default: "hi@dev.to",
        business: "business@dev.to",
        privacy: "privacy@dev.to",
        members: "members@dev.to"
      },
    )
  end

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
      SiteConfig.clear_cache
      expect(SiteConfig.email_addresses).to include(contact: contact_email)
    end
  end
end
