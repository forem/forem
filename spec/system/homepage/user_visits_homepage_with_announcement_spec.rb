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
    context "with an active announcement" do
      it "renders and dismisses the broadcast", :aggregate_failures, :js do
        create(:announcement_broadcast)
        visit_homepage

        expect_broadcast_data(page)

        find(".close-announcement-button").click
        expect_no_broadcast_data(page)
      end
    end

    context "without an active announcement" do
      it "does not render the broadcast", :js do
        create(:announcement_broadcast, active: false)
        visit_homepage

        expect_no_broadcast_data(page)
      end
    end
  end

  context "when user has logged in" do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    context "with an active announcement" do
      it "renders and dismisses the broadcast", :aggregate_failures, :js do
        create(:announcement_broadcast)
        visit_homepage

        expect_broadcast_data(page)

        find(".close-announcement-button").click
        expect_no_broadcast_data(page)
      end
    end

    context "when opting-out of announcements" do
      it "does not render the broadcast", :js do
        user.setting.update!(display_announcements: false)
        create(:announcement_broadcast, active: true)
        visit_homepage

        expect_no_broadcast_data(page)
      end
    end
  end
end
