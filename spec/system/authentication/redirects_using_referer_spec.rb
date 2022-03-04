require "rails_helper"

RSpec.describe "Redirects authentication using Referer", type: :system do
  let(:article) { build(:article) }
  let(:user) do
    create(:user, :with_identity, identities: [:twitter])
  end

  let(:login_link) { "Log in" }
  let(:sign_in_link) { "Continue with Twitter" }

  before do
    omniauth_mock_twitter_payload
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    OmniAuth.config.mock_auth[:twitter].info.email = user.email
  end

  after do
    sign_out user
  end

  context "when a valid referer is available" do
    it "redirects back to the main feed (root path)" do
      visit root_path
      click_link(login_link, match: :first)
      click_on(sign_in_link, match: :first)

      expect(page).to have_current_path("/", ignore_query: true)
    end

    it "redirects back to an article page" do
      visit "/#{article.slug}"
      click_link(login_link, match: :first)
      click_on(sign_in_link, match: :first)

      expect(page).to have_current_path("/#{article.slug}", ignore_query: true)
    end
  end

  context "when no referer is available" do
    it "redirects back to the main feed as default" do
      Capybara.current_session.driver.header "Referer", ""
      visit sign_up_path
      click_on(sign_in_link, match: :first)

      expect(page).to have_current_path("/", ignore_query: true)
    end
  end

  context "when the referer is from an external host" do
    it "redirects back to the main feed as default" do
      Capybara.current_session.driver.header "Referer", "https://example.com"
      visit sign_up_path
      click_on(sign_in_link, match: :first)

      expect(page).to have_current_path("/", ignore_query: true)
    end
  end
end
