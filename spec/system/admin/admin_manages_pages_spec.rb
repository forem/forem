require "rails_helper"

RSpec.describe "Admin manages pages", type: :system do

  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
    visit admin_pages_path
  end

  it "loads the view" do
    expect(page).to have_content("Pages")
    expect(page).to have_content("New page")
  end

  describe "when there are default pages" do
    it "shows an override defaults section with a warning" do
      expect(page).to have_content("Override defaults")
      expect(page).to have_content("Note: Proceed with caution.")
    end

    it "shows the code of conduct link in the overrides section" do
      within(".pages__override_defaults") do
        expect(page).to have_link("Code of Conduct", href: code_of_conduct_path)
        expect(page).to have_link("Override", href: new_admin_page_path(slug: "code-of-conduct"))
      end
    end

    it "shows the privacy policy link in the overrides section" do
      within(".pages__override_defaults") do
        expect(page).to have_link("Privacy Policy", href: privacy_path)
        expect(page).to have_link("Override", href: new_admin_page_path(slug: "privacy"))
      end
    end

    it "shows the terms of use link in the overrides section" do
      within(".pages__override_defaults") do
        expect(page).to have_link("Terms of Use", href: terms_path)
        expect(page).to have_link("Override", href: new_admin_page_path(slug: "terms"))
      end
    end

    it "does not show any of the links in the pages table" do
      within(".pages__table") do
        expect(page).to_not have_content("Terms of Use")
        expect(page).to_not have_content("Code of Conduct")
        expect(page).to_not have_content("Privacy Policy")
      end
    end
  end

  describe "when the defaults are overridden" do
    before do
      create(:page,
             slug: "code-of-conduct",
             body_html: "<div>Code of Conduct</div>",
             title: "Code of Conduct",
             description: "A page that describes how to behave on this platform",
             is_top_level_path: true)
      create(:page,
             slug: "privacy",
             body_html: "<div>Privacy Policy</div>",
             title: "Privacy Policy",
             description: "A page that describes the privacy policy", is_top_level_path: true
            )
      create(:page,
             slug: "terms",
             body_html: "<div>Terms of Use</div>",
             title: "Terms of Use",
             description: "A page that describes the terms of use for the application",
             is_top_level_path: true
            )
      sign_in admin
      visit admin_pages_path
    end

    it "shows the notice that the defaults have been overriden" do
      expect(page).to have_content("You will no longer receive updates on these pages from the Forem team")
    end

    it "shows the overriden pages in the pages table" do
      within(".pages__table") do
        expect(page).to have_content("Terms of Use")
        expect(page).to have_content("Code of Conduct")
        expect(page).to have_content("Privacy Policy")
      end
    end
  end
end
