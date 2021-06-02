require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201218080343_update_default_email_addresses.rb",
)

describe DataUpdateScripts::UpdateDefaultEmailAddresses do
  it "adds the default email" do
    described_class.new.run
    expect(Settings::General.email_addresses).to include(default: ApplicationConfig["DEFAULT_EMAIL"])
  end
end
