require "rails_helper"

RSpec.describe "Admin manages configuration", type: :system do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
    visit admin_config_path
  end

  # Note: The :meta_keywords are handled slightly differently in the view, so we
  # can't check them the same way as the rest.
  (VerifySetupCompleted::MANDATORY_CONFIGS - [:meta_keywords]).each do |option|
    it "marks #{option} as required" do
      selector = "label[for='site_config_#{option}']"
      expect(first(selector).text).to include("Required")
    end
  end

  context "when mandatory options are missing" do
    it "does not show the banner on the config page" do
      allow(SiteConfig).to receive(:tagline).and_return(nil)
      expect(page).not_to have_content("Setup not completed yet")
    end

    it "does show the banner on other pages" do
      allow(SiteConfig).to receive(:tagline).and_return(nil)
      visit root_path
      expect(page).to have_content("Setup not completed yet")
    end

    it "includes information about missing fields on the config pages" do
      allow(SiteConfig).to receive(:tagline).and_return(nil)
      allow(SiteConfig).to receive(:suggested_users).and_return(nil)
      allow(SiteConfig).to receive(:suggested_tags).and_return(nil)
      allow(SiteConfig).to receive(:community_action).and_return(nil)
      visit root_path
      expect(page.body).to match(/Setup not completed yet, missing(.*)community action(.*), and others/)
    end
  end
end
