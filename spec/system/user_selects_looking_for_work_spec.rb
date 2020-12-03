require "rails_helper"

RSpec.describe "Looking For Work", type: :system do
  let(:user) { create(:user) }

  before do
    user.follow(create(:tag, name: "hiring"))
  end

  it "user selects looking for work and autofollows hiring tag", js: true do
    allow(SiteConfig).to receive(:dev_to?).and_return(true)

    sign_in(user)
    visit "/settings"
    page.check("profile[looking_for_work]")
    sidekiq_perform_enqueued_jobs { click_button("Save") }

    expect(page).to have_text("Your profile has been updated")
    expect(user.follows.count).to eq(1)
  end
end
