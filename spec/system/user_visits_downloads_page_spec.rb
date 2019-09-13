require "rails_helper"

RSpec.describe "User visits downloads page", type: :system do
  before { visit "/downloads" }

  it "shows app links" do
    within ".links" do
      expect(page).to have_link(nil, href: "https://apps.apple.com/us/app/dev-community/id1439094790")
      expect(page).to have_link(nil, href: "https://play.google.com/store/apps/details?id=to.dev.dev_android")
    end
  end
end
