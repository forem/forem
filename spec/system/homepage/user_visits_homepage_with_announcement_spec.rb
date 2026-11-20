require "rails_helper"

RSpec.describe "User visits a homepage" do
  def visit_homepage
    visit "/"
    expect(page).to have_css("body[data-loaded='true']", wait: 30)
  end

  def expect_broadcast_data(page)
    expect(page).to have_css(".broadcast-wrapper .broadcast-data", text: "Hello, World!")
  end

  def expect_no_broadcast_data(page)
    expect(page).to have_no_css(".broadcast-wrapper .broadcast-data")
  end

  context "when user hasn't logged in" do
    it "omits inactive announcements and renders and dismisses active announcements", :aggregate_failures, :js do
      broadcast = create(:announcement_broadcast, active: false)
      visit_homepage

      expect_no_broadcast_data(page)

      broadcast.update!(active: true)
      visit_homepage

      expect_broadcast_data(page)

      find(".close-announcement-button").click
      expect_no_broadcast_data(page)
    end
  end

  context "when user has logged in" do
    let(:user) { create(:user, :without_profile, profile_image: nil) }

    before do
      sign_in(user)
    end

    it "omits announcements when opted out and renders and dismisses them when enabled", :aggregate_failures, :js do
      expect(user.setting.display_announcements).to be(true)
      user.setting.update!(display_announcements: false)
      create(:announcement_broadcast, active: true)
      visit_homepage

      expect_no_broadcast_data(page)

      user.setting.update!(display_announcements: true)
      visit_homepage

      expect_broadcast_data(page)

      find(".close-announcement-button").click
      expect_no_broadcast_data(page)
    end
  end
end
