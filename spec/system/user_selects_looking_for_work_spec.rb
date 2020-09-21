require "rails_helper"

RSpec.describe "Looking For Work", type: :system do
  let(:user) { create(:user) }

  before do
    create(:tag, name: "hiring")
    create(:profile_field, label: "Looking for work", input_type: :check_box)
    Profile.refresh_attributes!
    sign_in(user)
    visit "/settings"
  end

  xit "user selects looking for work and autofollows hiring tag", js: true do
    page.find_by(id: "profile[looking_for_work]").check
    sidekiq_perform_enqueued_jobs do
      click_button("Save")
    end
    expect(page).to have_text("Your profile has been updated")
    expect(user.follows.count).to eq(1)
  end
end
