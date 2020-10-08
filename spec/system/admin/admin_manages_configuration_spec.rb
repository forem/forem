require "rails_helper"

RSpec.describe "Admin manages configuration", type: :system do
  let(:single_resource_admin) { create(:user, :single_resource_admin) }

  context "when on the config page" do
    before do
      sign_in single_resource_admin
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
  end

  describe "setup completed banner" do
    context "when logged in as single resource admin" do
      it "does not show the banner on the config page" do
        allow(SiteConfig).to receive(:logo_png).and_return(nil)

        sign_in single_resource_admin
        visit admin_config_path

        expect(page).not_to have_content("Setup not completed yet")
      end

      it "shows the banner on other pages for single resource admins" do
        allow(SiteConfig).to receive(:logo_png).and_return(nil)

        sign_in single_resource_admin
        visit root_path

        expect(page).to have_content("Setup not completed yet")
      end

      it "includes information about missing fields on the config pages" do
        allow(SiteConfig).to receive(:logo_png).and_return(nil)
        allow(SiteConfig).to receive(:suggested_users).and_return(nil)
        allow(SiteConfig).to receive(:suggested_tags).and_return(nil)

        sign_in single_resource_admin
        visit root_path

        expect(page.body).to match(/Setup not completed yet, missing(.*)main social image(.*), and others/)
      end
    end

    context "when logged in as other user type" do
      it "does not show the banner for admins" do
        sign_in create(:user, :admin)
        visit root_path

        expect(page).not_to have_content("Setup not completed yet")
      end

      it "does not show the banner for users" do
        sign_in create(:user)
        visit root_path

        expect(page).not_to have_content("Setup not completed yet")
      end
    end
  end
end
