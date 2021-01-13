require "rails_helper"

RSpec.describe "User destroys their profile", type: :system, js: true do
  let(:user) { create(:user) }
  let(:token) { SecureRandom.hex(10) }
  let(:mismatched_token) { SecureRandom.hex(10) }

  before do
    sign_in user
  end

  it "requests self-destroy" do
    visit "/settings/account"
    allow(Users::RequestDestroy).to receive(:call).and_call_original
    click_button "Delete Account"
    expect(Users::RequestDestroy).to have_received(:call).with(user)
  end

  it "displays a detailed error message when the user's token is invalid" do
    visit "/settings/account"
    click_button "Delete Account"
    allow(Rails.cache).to receive(:exist?).with("user-destroy-token-#{user.id}").and_return(false)
    expect do
      get user_confirm_destroy_path(token: token)
    end.to raise_error(UserDestroyToken::Errors::InvalidToken)
  end

  it "raises a 'Not Found' error if there is a token mismatch" do
    visit "/settings/account"
    click_button "Delete Account"
    allow(Rails.cache).to receive(:read).and_return(token)
    expect do
      get user_confirm_destroy_path(token: mismatched_token)
    end.to raise_error(ActionController::RoutingError)
  end

  it "destroys an account" do
    allow(Rails.cache).to receive(:read).and_return(token)
    visit "/users/confirm_destroy/#{token}"
    fill_in "delete__account__username__field", with: user.username
    fill_in "delete__account__verification__field", with: "delete my account"
    sidekiq_assert_enqueued_with(job: Users::DeleteWorker) do
      click_button "DELETE ACCOUNT"
    end
  end
end
