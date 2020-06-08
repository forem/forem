require "rails_helper"

RSpec.describe "Announcements", type: :system do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit "/settings/misc"
  end

  it "renders the announcements settings" do
    expect(page).to have_text("Announcements")
  end

  it "properly updates the announcements settings", js: true do
    page.check "Display Announcements (When browsing)"
    sidekiq_perform_enqueued_jobs do
      click_button("Save Announcements Settings")
    end
    expect(page).to have_text("Your profile was successfully updated.")
  end
end
