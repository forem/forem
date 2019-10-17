require "rails_helper"

RSpec.describe "User destroys their profile", type: :system, js: true do
  let(:user) { create(:user, saw_onboarding: true) }

  before do
    sign_in user
  end

  it "destroys a user without content" do
    visit "/settings/account"
    fill_in "delete__account__username__field", with: user.username
    fill_in "delete__account__verification__field", with: "delete my account"
    click_button "DELETE ACCOUNT"
    expect(User.find_by(id: user.id).present?).to be false
  end

  it "destroys a user with content" do
    create(:article, user: user)
    user.update_attribute(:articles_count, 1)
    visit "/settings/account"
    fill_in "delete__account__username__field", with: user.username
    fill_in "delete__account__verification__field", with: "delete my account"
    expect do
      click_button "DELETE ACCOUNT"
    end.to have_enqueued_job(Users::SelfDeleteJob)
  end
end
