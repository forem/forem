require "rails_helper"

RSpec.describe "Looking For Work", type: :system do
  let(:user) { create(:user) }

  before do
    create(:tag, name: "hiring")
    sign_in(user)
    visit "/settings"
  end

  # TODO: Uncomment this spec when we decide to use percy again
  xit "renders the page", js: true, percy: true do
    Percy.snapshot(page, name: "Logged in user: settings page")
  end

  it "user selects looking for work and autofollows hiring tag", js: true do
    page.check "Looking for work"
    sidekiq_perform_enqueued_jobs do
      click_button("Save")
    end
    expect(page).to have_text("Your profile was successfully updated")
    expect(user.follows.count).to eq(1)
  end
end
