require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220126102900_create_home_navigation_link.rb",
)

describe DataUpdateScripts::CreateHomeNavigationLink do
  it "creates a home navigation link when it doesn't already exist" do
    expect do
      described_class.new.run
    end.to change(NavigationLink, :count).by(1)
  end

  it "skips home navigation link creation if already exists" do
    create(:navigation_link, url: "/")
    expect do
      described_class.new.run
    end.not_to change(NavigationLink, :count)
  end
end
