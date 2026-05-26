require "rails_helper"

RSpec.describe "User visits a homepage" do
  def expect_broadcast_data(page)
    expect(page).to have_selector(".broadcast-wrapper .broadcast-data", text: "Hello, World!")
  end

  def expect_no_broadcast_data(page)
    expect(page).not_to have_css(".broadcast-wrapper .broadcast-data")
  end

  context "when user hasn't logged in" do
    context "with an active announcement" do
      before do
        create(:announcement_broadcast)
        visit "/"
        expect(page).to have_selector("body[data-loaded='true']")
      end

      it "renders the broadcast", js: true do
        expect_broadcast_data(page)
      end

      it "dismisses the broadcast", js: true do
        expect_broadcast_data(page)

        find(".close-announcement-button").click
        expect_no_broadcast_data(page)
      end
    end

    context "without an active announcement" do
      before do
        create(:announcement_broadcast, active: false)
        visit "/"
        expect(page).to have_selector("body[data-loaded='true']")
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
        visit "/"
        expect(page).to have_selector("body[data-loaded='true']")
      end

      it "renders the broadcast", js: true do
        expect_broadcast_data(page)
      end

      it "dismisses the broadcast", js: true do
        visit "/"
        expect(page).to have_selector("body[data-loaded='true']")
        expect_broadcast_data(page)

        find(".close-announcement-button").click
        expect_no_broadcast_data(page)
      end
    end

    context "without an active announcement" do
      before do
        create(:announcement_broadcast, active: false)
        visit "/"
        expect(page).to have_selector("body[data-loaded='true']")
      end

      it "does not render the broadcast", js: true do
        expect_no_broadcast_data(page)
      end
    end

    context "when opting-out of announcements" do
      before do
        user.setting.update!(display_announcements: false)
        create(:announcement_broadcast, active: true)
        visit "/"
        expect(page).to have_selector("body[data-loaded='true']")
      end

      it "does not render the broadcast", js: true do
        expect_no_broadcast_data(page)
      end
    end
  end
end
