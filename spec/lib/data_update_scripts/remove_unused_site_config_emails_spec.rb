require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210509105151_remove_unused_site_config_emails.rb",
)

describe DataUpdateScripts::RemoveUnusedSiteConfigEmails do
  let(:contact_email) { "contact@dev.to" }

  before do
    Settings::General.email_addresses = {
      default: ApplicationConfig["DEFAULT_EMAIL"],
      contact: "contact@dev.to",
      business: "business@dev.to",
      privacy: "privacy@dev.to",
      members: "members@dev.to"
    }
  end

  it "removes the unused emails" do
    described_class.new.run
    expect(Settings::General.email_addresses.symbolize_keys).to eq(default: ApplicationConfig["DEFAULT_EMAIL"])
  end
end
