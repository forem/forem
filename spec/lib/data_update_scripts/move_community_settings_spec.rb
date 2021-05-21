require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210419063311_move_community_settings.rb",
)

describe DataUpdateScripts::MoveCommunitySettings do
  it "migrates renamed settings", :aggregate_failures do
    allow(SiteConfig).to receive(:community_copyright_start_year).and_return(2564)
    allow(SiteConfig).to receive(:community_member_label).and_return("star")

    expect { described_class.new.run }
      .to change(Settings::Community, :copyright_start_year).to(2564)
      .and change(Settings::Community, :member_label).to("star")
  end

  it "migrates non-renamed settings" do
    allow(SiteConfig).to receive(:staff_user_id).and_return(42)
    allow(SiteConfig).to receive(:tagline).and_return("D'oh")

    expect { described_class.new.run }
      .to change(Settings::Community, :staff_user_id).to(42)
      .and change(Settings::Community, :tagline).to("D'oh")
  end
end
