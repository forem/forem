require "rails_helper"

RSpec.describe "Banned user tries to sign up again" do
  before do
    omniauth_mock_twitter_payload

    allow(SiteConfig)
      .to receive(:authentication_providers)
      .and_return(Authentication::Providers.available)

    allow(ForemStatsClient).to receive(:increment)
  end

  context "when a user has been previously banned", :aggregate_failures do
    it "displays an error message" do
      username = OmniAuth.config.mock_auth[:twitter].extra.raw_info.username
      create(:suspended_user, username: username)

      visit sign_up_path
      click_on("Continue with Twitter", match: :first)
      expect(page).to have_current_path(root_path)

      expected_message = ::Authentication::Errors::PreviouslyBanned.new.message
      expect(page).to have_content(expected_message)
      expect(ForemStatsClient)
        .to have_received(:increment)
        .with("identity.errors",
              tags: [
                "error:Authentication::Errors::PreviouslyBanned",
                "message:#{expected_message}",
              ])
    end
  end
end
