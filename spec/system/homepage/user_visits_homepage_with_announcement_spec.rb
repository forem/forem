require "rails_helper"

def expect_broadcast_data(page)
  within ".broadcast-wrapper" do
    expect(page).to have_selector(".broadcast-data")
    expect(page).to have_text("Hello, World!")
  end
end

def expect_no_broadcast_data(page)
  expect(page).not_to have_css(".broadcast-wrapper")
  expect(page).not_to have_selector(".broadcast-data")
  expect(page).not_to have_text("Hello, World!")
end

RSpec.describe "User visits a homepage", type: :system do
  context "when user hasn't logged in" do
    context "with an active announcement" do
      before do
        create(:announcement_broadcast)
        get "/async_info/base_data" # Explicitly ensure broadcast data is loaded before doing any checks
        visit "/"
      end

      it "renders the broadcast", js: true do
        expect_broadcast_data(page)
      end

      it "dismisses the broadcast", js: true do
        wait_for_javascript

        find(".close-announcement-button").click
        expect_no_broadcast_data(page)
      end
    end

    context "without an active announcement" do
      before do
        create(:announcement_broadcast, active: false)
        get "/async_info/base_data" # Explicitly ensure broadcast data is loaded before doing any checks
        visit "/"
      end

      it "does not render the broadcast", js: true do
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
      before do
        create(:announcement_broadcast)
        get "/async_info/base_data" # Explicitly ensure broadcast data is loaded before doing any checks
        visit "/"
      end

      it "renders the broadcast", js: true do
        expect_broadcast_data(page)
      end

      it "dismisses the broadcast", js: true do
        get "/async_info/base_data"
        visit "/"
        wait_for_javascript

        find(".close-announcement-button").click
        expect_no_broadcast_data(page)
      end
    end

    context "without an active announcement" do
      before do
        create(:announcement_broadcast, active: false)
        get "/async_info/base_data" # Explicitly ensure broadcast data is loaded before doing any checks
        visit "/"
      end

      it "does not render the broadcast", js: true do
        expect_no_broadcast_data(page)
      end
    end

    context "when opting-out of announcements" do
      before do
        user.update!(display_announcements: false)
        create(:announcement_broadcast, active: true)
        get "/async_info/base_data" # Explicitly ensure broadcast data is loaded before doing any checks
        visit "/"
      end

      it "does not render the broadcast", js: true do
        expect_no_broadcast_data(page)
      end
    end
  end
end
