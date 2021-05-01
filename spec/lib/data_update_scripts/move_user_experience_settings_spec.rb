require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210426023014_move_user_experience_settings.rb",
)

describe DataUpdateScripts::MoveUserExperienceSettings do
  it "moves existing settings" do
    allow(SiteConfig).to receive(:default_font).and_return("Comic Sans")
    allow(SiteConfig).to receive(:primary_brand_color_hex).and_return("#000")

    expect do
      described_class.new.run
    end
      .to change(Settings::UserExperience, :default_font).to("Comic Sans")
      .and change(Settings::UserExperience, :primary_brand_color_hex).to("#000")
  end
end
