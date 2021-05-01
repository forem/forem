require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210420050256_move_mascot_settings.rb",
)

describe DataUpdateScripts::MoveMascotSettings do
  before do
    allow(SiteConfig).to receive(:mascot_footer_image_url)
      .and_return("https://example.com/mascot.png")
  end

  it "moves renamed settings" do
    allow(SiteConfig).to receive(:mascot_image_description).and_return("Bla")

    expect do
      described_class.new.run
    end
      .to change(Settings::Mascot, :image_description)
      .and change(Settings::Mascot, :footer_image_url)
  end

  it "moves the non-renamed./spec/lib/data_update_scripts/move_mascot_settings_spec.rb setting" do
    allow(SiteConfig).to receive(:mascot_user_id).and_return(42)
    expect do
      described_class.new.run
    end.to change(Settings::Mascot, :mascot_user_id).to(42)
  end
end
