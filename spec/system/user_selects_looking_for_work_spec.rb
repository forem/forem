require "rails_helper"

RSpec.describe "Looking For Work", type: :system do
  let(:user) { create(:user) }
  let(:tag) { create(:tag, name: "hiring") }

  before do
    sign_in(user)
    tag
  end

  it "user selects looking for work and autofollows hiring tag", js: true do
    visit "/settings"

    Percy.snapshot(page, name: "Logged in user: settings page")

    page.check "Looking for work"
    sidekiq_perform_enqueued_jobs do
      click_button("Save")
    end
    expect(page).to have_text("Your profile was successfully updated")
    expect(user.follows.count).to eq(1)
  end
end
