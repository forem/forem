require "rails_helper"

RSpec.describe "Conditional registration (ForemWebView)" do
  let(:all_providers) { Authentication::Providers.available }
  let(:all_providers_except_apple) { Authentication::Providers.available - %i[apple] }
  let(:all_providers_minus_apple_forem) { Authentication::Providers.available - %i[apple forem] }
  let(:mobile_browser_ua) { "Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148" }
  let(:foremwebview_ua) do
    "Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 ForemWebView/1.0"
  end
  let(:flow_b_fallback_text) do
    "Unfortunately, we do not support creating new accounts right now on our " \
      "mobile app. If you want create a new account to join " \
      "#{Settings::Community.community_name}, please do that on the web at"
  end

  before do
    allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
  end

  def expect_authentication_options(user_agent, state:, included:, excluded: [])
    get sign_up_path(state: state), headers: { "HTTP_USER_AGENT" => user_agent }

    included.each { |text| expect(response.body).to include(text) }
    excluded.each { |text| expect(response.body).not_to include(text) }
  end

  context "when browsing using mobile browser" do
    it "renders the social providers when all providers are enabled" do
      allow(Settings::Authentication).to receive(:providers).and_return(all_providers)

      expect_authentication_options(mobile_browser_ua, state: "new-user",
                                                       included: ["Sign up with Apple", "Sign up with GitHub",
                                                                  "Sign up with Email"])
      expect_authentication_options(mobile_browser_ua, state: nil,
                                                       included: ["Continue with Apple", "Continue with GitHub"])
    end

    it "renders the social providers when all providers except Apple are enabled" do
      allow(Settings::Authentication).to receive(:providers).and_return(all_providers_except_apple)

      expect_authentication_options(mobile_browser_ua, state: "new-user",
                                                       included: ["Sign up with GitHub", "Sign up with Email"],
                                                       excluded: ["Sign up with Apple"])
      expect_authentication_options(mobile_browser_ua, state: nil,
                                                       included: ["Continue with GitHub"],
                                                       excluded: ["Continue with Apple"])
    end
  end

  context "when browsing using ForemWebView" do
    it "renders the social providers if Apple Auth is enabled" do
      allow(Settings::Authentication).to receive(:providers).and_return(all_providers)

      expect_authentication_options(foremwebview_ua, state: "new-user",
                                                     included: ["Sign up with Apple", "Sign up with GitHub",
                                                                "Sign up with Email"])
      expect_authentication_options(foremwebview_ua, state: nil,
                                                     included: ["Continue with Apple", "Continue with GitHub"])
    end

    it "doesn't render social providers if Apple Auth isn't enabled" do
      allow(Settings::Authentication).to receive(:providers).and_return(all_providers_except_apple)

      expect_authentication_options(foremwebview_ua, state: "new-user",
                                                     included: ["Sign up with Email"],
                                                     excluded: ["Sign up with Apple", "Sign up with GitHub"])
      expect_authentication_options(foremwebview_ua, state: nil,
                                                     included: [],
                                                     excluded: ["Continue with Apple", "Continue with GitHub"])
    end

    context "when Apple Auth and email registration aren't enabled" do
      before do
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(false)
      end

      it "renders the fallback message if Forem Auth is also disabled" do
        allow(Settings::Authentication).to receive(:providers).and_return(all_providers_minus_apple_forem)

        expect_authentication_options(foremwebview_ua, state: "new-user",
                                                       included: ["Sorry to be a bummer...", flow_b_fallback_text],
                                                       excluded: ["Sign up with Apple", "Sign up with GitHub",
                                                                  "Sign up with Forem"])
        expect_authentication_options(foremwebview_ua, state: nil, included: [],
                                                       excluded: ["Continue with Apple", "Continue with GitHub",
                                                                  flow_b_fallback_text])
      end

      it "doesn't render the fallback because Forem Auth is enabled" do
        allow(Settings::Authentication).to receive(:providers).and_return(all_providers_except_apple)

        expect_authentication_options(foremwebview_ua, state: "new-user",
                                                       included: ["Sign up with Forem"],
                                                       excluded: ["Sign up with GitHub", "Sorry to be a bummer...",
                                                                  flow_b_fallback_text])
        expect_authentication_options(foremwebview_ua, state: nil,
                                                       included: ["Continue with Forem"],
                                                       excluded: ["Continue with Apple", "Continue with GitHub"])
      end
    end
  end
end
