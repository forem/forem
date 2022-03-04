require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220201114309_update_home_navigation_link_position.rb",
)

describe DataUpdateScripts::UpdateHomeNavigationLinkPosition do
  it "creates a home navigation link when it doesn't already exist" do
    expect do
      described_class.new.run
    end.to change { NavigationLink.exists?(url: "/", name: "Home", position: 1) }.from(false).to(true)
  end

  it "updates any existing home navigation link to have position 1" do
    link = create(:navigation_link, url: "/", name: "Home", position: 4)
    described_class.new.run
    expect(link.reload.position).to eq(1)
  end
end
