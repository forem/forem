require "rails_helper"

# E2E tests for API key management on the settings/extensions page.
#
# Regression coverage for:
#   - https://github.com/forem/forem/issues/23031
#   - https://github.com/forem/forem/issues/23090

RSpec.describe "User manages API secrets" do
  let(:user) { create(:user) }

  context "when signed in" do
    before do
      sign_in user
    end

    it "generates an API key, stays on the extensions page, and displays the secret", :aggregate_failures do
      visit "/settings/extensions"

      fill_in "api_secret[description]", with: "My Test App"
      click_on "Generate API Key"

      expect(page).to have_current_path("/settings/extensions")
      expect(page).to have_text("Active API keys")
      expect(page).to have_text("My Test App")
      expect(user.api_secrets.count).to eq(1)

      secret = user.api_secrets.last
      expect(secret.description).to eq("My Test App")

      find("details", text: "My Test App").click
      expect(page).to have_css("p.ff-monospace", text: secret.secret)
    end

    it "revokes an existing API key", :aggregate_failures do
      create(:api_secret, user: user, description: "Old Key")

      visit "/settings/extensions"
      find("details", text: "Old Key").click
      click_on "Revoke"

      expect(page).to have_current_path("/settings/extensions")
      expect(page).to have_no_text("Old Key")
      expect(user.api_secrets.count).to eq(0)
    end
  end

  context "when not signed in" do
    it "redirects to authentication when visiting settings/extensions" do
      visit "/settings/extensions"
      expect(page).to have_current_path("/enter")
    end
  end
end
