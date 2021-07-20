require "rails_helper"

# This test file can be removed once we have a longterm solution for
# ForemWebView contexts when Apple Auth isn't enabled
RSpec.describe "Conditional registration (ForemWebView)", type: :system do
  let(:all_providers) { Authentication::Providers.available }
  let(:all_providers_except_apple) { Authentication::Providers.available - [:apple] }
  let(:mobile_browser_ua) { "Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148" }
  let(:foremwebview_ua) do
    "Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 ForemWebView/1.0"
  end
  let(:flow_b_fallback_text) do
    "Unfortunately, we do not support creating new accounts right now on our "\
      "mobile app. If you want create a new account to join "\
      "#{Settings::Community.community_name}, please do that on the web at"
  end

  before do
    allow(FeatureFlag).to receive(:enabled?).with(:apple_auth).and_return(true)
    allow(FeatureFlag).to receive(:enabled?).with(:creator_onboarding).and_return(false)
    allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
  end

  context "when browsing using mobile browser" do
    before { Capybara.current_session.driver.header("User-Agent", mobile_browser_ua) }

    it "renders the social providers when all providers are enabled" do
      # All auth options enabled for registration
      allow(Settings::Authentication).to receive(:providers).and_return(all_providers)
      visit sign_up_path(state: "new-user")
      expect(page).to have_text("Sign up with Apple")
      expect(page).to have_text("Sign up with GitHub")
      expect(page).to have_text("Sign up with Email")

      # All auth options enabled for login
      visit sign_up_path
      expect(page).to have_text("Continue with Apple")
      expect(page).to have_text("Continue with GitHub")
      expect(page).to have_text("Have a password? Continue with your email address")
    end

    it "renders the social providers when all providers except Apple are enabled" do
      # All auth options except apple for registration
      allow(Settings::Authentication).to receive(:providers).and_return(all_providers_except_apple)
      visit sign_up_path(state: "new-user")
      expect(page).not_to have_text("Sign up with Apple")
      expect(page).to have_text("Sign up with GitHub")
      expect(page).to have_text("Sign up with Email")

      # All auth options except apple for login
      visit sign_up_path
      expect(page).not_to have_text("Continue with Apple")
      expect(page).to have_text("Continue with GitHub")
      expect(page).to have_text("Have a password? Continue with your email address")
    end
  end

  context "when browsing using ForemWebView" do
    before { Capybara.current_session.driver.header("User-Agent", foremwebview_ua) }

    it "renders the social providers if Apple Auth is enabled" do
      # Renders the social provider options because Apple Auth is available for registration
      allow(Settings::Authentication).to receive(:providers).and_return(all_providers)
      visit sign_up_path(state: "new-user")
      expect(page).to have_text("Sign up with Apple")
      expect(page).to have_text("Sign up with GitHub")
      expect(page).to have_text("Sign up with Email")

      # Renders the social provider options because Apple Auth is available for login
      visit sign_up_path
      expect(page).to have_text("Continue with Apple")
      expect(page).to have_text("Continue with GitHub")
      expect(page).to have_text("Have a password? Continue with your email address")
    end

    it "doesn't render social providers if Apple Auth isn't enabled" do
      # Only renders email option because Apple Auth isn't available for registration
      allow(Settings::Authentication).to receive(:providers).and_return(all_providers_except_apple)
      visit sign_up_path(state: "new-user")
      expect(page).not_to have_text("Sign up with Apple")
      expect(page).not_to have_text("Sign up with GitHub")
      expect(page).to have_text("Sign up with Email")

      # Only renders email option because Apple Auth isn't available for login
      visit sign_up_path
      expect(page).not_to have_text("Continue with Apple")
      expect(page).not_to have_text("Continue with GitHub")
      expect(page).to have_text("Have a password? Continue with your email address")
    end

    it "renders the fallback message when Apple Auth and email registration aren't enabled" do
      # Only renders email option because Apple Auth isn't available for registration
      allow(Settings::Authentication).to receive(:providers).and_return(all_providers_except_apple)
      allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(false)
      visit sign_up_path(state: "new-user")
      expect(page).not_to have_text("Sign up with Apple")
      expect(page).not_to have_text("Sign up with GitHub")
      expect(page).not_to have_text("Sign up with Email")
      expect(page).to have_text("Sorry to be a bummer...")
      expect(page).to have_text(flow_b_fallback_text)

      # Only renders email option because Apple Auth isn't available for login
      visit sign_up_path
      expect(page).not_to have_text("Continue with Apple")
      expect(page).not_to have_text("Continue with GitHub")
      expect(page).to have_text("Have a password? Continue with your email address")
    end
  end
end
