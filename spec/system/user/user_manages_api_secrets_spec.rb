require "rails_helper"

# E2E tests for API key management on the settings/extensions page.
#
# Regression coverage for:
#   - https://github.com/forem/forem/issues/23031
#   - https://github.com/forem/forem/issues/23090

RSpec.describe "User manages API secrets", :js do
  let(:user) { create(:user) }

  context "when signed in" do
    before do
      sign_in user
    end

    it "generates an API key from the extensions settings page" do
      visit "/settings/extensions"

      fill_in "api_secret[description]", with: "My Test App"
      click_button "Generate API Key"

      expect(page).to have_text("Active API keys")
      expect(page).to have_text("My Test App")
      expect(user.api_secrets.count).to eq(1)
      expect(user.api_secrets.last.description).to eq("My Test App")
    end

    it "displays the generated key secret in the active keys section" do
      visit "/settings/extensions"

      fill_in "api_secret[description]", with: "Visible Key"
      click_button "Generate API Key"

      expect(page).to have_text("Visible Key")

      secret = user.api_secrets.last
      find("details", text: "Visible Key").click
      expect(page).to have_text(secret.secret)
    end

    it "revokes an existing API key" do
      create(:api_secret, user: user, description: "Old Key")

      visit "/settings/extensions"
      find("details", text: "Old Key").click
      click_button "Revoke"

      expect(page).not_to have_text("Old Key")
      expect(user.api_secrets.count).to eq(0)
    end

    it "stays on the extensions page after generating a key" do
      visit "/settings/extensions"

      fill_in "api_secret[description]", with: "Stay Here"
      click_button "Generate API Key"

      expect(page).to have_current_path("/settings/extensions")
    end
  end

  context "when not signed in" do
    it "redirects to authentication when visiting settings/extensions" do
      visit "/settings/extensions"
      expect(page).not_to have_current_path("/settings/extensions")
    end
  end
end
