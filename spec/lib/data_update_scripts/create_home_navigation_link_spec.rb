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
    create(:navigation_link, url: "/", name: "Home")
    expect do
      described_class.new.run
    end.not_to change(NavigationLink, :count)
  end

  it "updates the position of other default navigation links" do
    link = create(:navigation_link, url: "/example", name: "Example", section: :default, position: 0)
    described_class.new.run
    expect(link.reload.position).to eq(2)
  end

  it "doesn't update the position of other navigation links" do
    link = create(:navigation_link, url: "/example", name: "Example", section: :other, position: 0)
    described_class.new.run
    expect(link.reload.position).to eq(0)
  end
end
