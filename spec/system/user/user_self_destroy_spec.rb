require "rails_helper"

RSpec.describe "User destroys their profile", type: :system, js: true do
  let(:user) { create(:user, saw_onboarding: true) }

  before do
    sign_in user
  end

  it "requests self-destroy" do
    visit "/settings/account"
    allow(Users::RequestDestroy).to receive(:call).and_call_original
    click_button "DELETE ACCOUNT"
    expect(Users::RequestDestroy).to have_received(:call).with(user)
  end

  it "destroys an account" do
    token = SecureRandom.hex(10)
    allow(Rails.cache).to receive(:read).and_return(token)
    visit "/users/confirm_destroy/#{token}"
    fill_in "delete__account__username__field", with: user.username
    fill_in "delete__account__verification__field", with: "delete my account"
    sidekiq_assert_enqueued_with(job: Users::DeleteWorker) do
      click_button "DELETE ACCOUNT"
    end
  end
end
