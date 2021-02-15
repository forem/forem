require "rails_helper"

RSpec.describe "User destroys their profile", type: :system, js: true do
  let(:user) { create(:user) }
  let(:token) { SecureRandom.hex(10) }
  let(:mismatch_token) { SecureRandom.hex(10) }

  before do
    sign_in user
    allow(Honeycomb).to receive(:add_field)
  end

  it "requests self-destroy" do
    visit "/settings/account"
    allow(Users::RequestDestroy).to receive(:call).and_call_original
    click_button "Delete Account"
    expect(Users::RequestDestroy).to have_received(:call).with(user)
  end

  it "displays a detailed error message when the user is not logged in" do
    sign_out user
    visit "/users/confirm_destroy/#{token}"
    expect(page).to have_text("You must be logged in to proceed with account deletion.")
  end

  it "displays a detailed error message when the user's token is invalid" do
    visit "/users/confirm_destroy/#{token}"
    # rubocop:disable Layout/LineLength
    expect(page).to have_text("Your token has expired, please request a new one. Tokens only last for 12 hours after account deletion is initiated.")
    # rubocop:enable Layout/LineLength
  end

  it "raises a 'Not Found' error if there is a token mismatch" do
    visit "/settings/account"
    click_button "Delete Account"
    allow(Rails.cache).to receive(:read).and_return(token)
    expect do
      get user_confirm_destroy_path(token: mismatch_token)
    end.to raise_error(ActionController::RoutingError)
    expect(Honeycomb).to have_received(:add_field).with("destroy_token", token)
    expect(Honeycomb).to have_received(:add_field).with("token", mismatch_token)
  end

  it "destroys an account" do
    allow(Rails.cache).to receive(:read).and_return(token)
    visit "/users/confirm_destroy/#{token}"
    fill_in "delete__account__username__field", with: user.username
    fill_in "delete__account__verification__field", with: "delete my account"
    sidekiq_assert_enqueued_with(job: Users::DeleteWorker) do
      click_button "Delete account"
    end
  end
end
