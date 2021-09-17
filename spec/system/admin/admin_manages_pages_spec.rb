require "rails_helper"

RSpec.describe "Admin manages pages", type: :system do
  let(:admin) { create(:user, :super_admin) }

  before do
    create(:page,
           slug: "test-page",
           body_html: "<div>hello there</div>",
           title: "Test Page",
           description: "A test page",
           is_top_level_path: true,
           landing_page: false)
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
        expect(page).not_to have_content("Terms of Use")
        expect(page).not_to have_content("Code of Conduct")
        expect(page).not_to have_content("Privacy Policy")
      end
    end

    it "has client-side validation" do
      expect(page).to have_content("Test Page")
      click_on("Edit")
      fill_in "page_description", with: ""
      click_on("Update Page")
      expect(page).not_to have_current_path(admin_pages_path)
      fill_in "page_description", with: "Walk without rhythm"
      fill_in "page_slug", with: "不"
      click_on("Update Page")
      expect(page).not_to have_current_path(admin_pages_path)
    end

    it "allows a page to be deleted" do
      expect(page).to have_content("Test Page")
      click_on("Edit")
      expect(page).to have_selector("input[type=submit][value='Delete Page']")
      click_on("Delete Page")
      expect(page).to have_current_path(admin_pages_path)
      expect(page).not_to have_content("Test Page")
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
             description: "A page that describes the privacy policy", is_top_level_path: true)
      create(:page,
             slug: "terms",
             body_html: "<div>Terms of Use</div>",
             title: "Terms of Use",
             description: "A page that describes the terms of use for the application",
             is_top_level_path: true)
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

  describe "when there is a landing page" do
    let(:current_landing_page) { create(:page, landing_page: true) }
    let(:new_landing_page) { create(:page, landing_page: true) }

    context "when a Forem is private" do
      before do
        allow(ForemInstance).to receive(:private?).and_return(true)
      end

      it "allows a landing page to be updated", :aggregate_failures do
        visit edit_admin_page_path(current_landing_page.id)
        expect(page).to have_content("Use as 'Locked Screen'")
        uncheck "Use as 'Locked Screen'"
        click_on("Update Page")
        expect(page).to have_current_path(admin_pages_path)
      end

      it "allows an Admin to click through to the current landing page via the modal", :aggregate_failures do
        visit edit_admin_page_path(new_landing_page.id)
        expect(page).to have_content("Use as 'Locked Screen'")
        check "Use as 'Locked Screen'"
        expect(page).to have_link("Current Locked Screen: #{new_landing_page.title}")
        click_on("Current Locked Screen")
        expect(page).to have_current_path(new_landing_page.path)
        expect(page).to have_content(new_landing_page.title)
      end

      it "allows an Admin to overwrite the current landing page via the checkbox and modal", :aggregate_failures do
        visit edit_admin_page_path(new_landing_page.id)
        expect(page).to have_content("Use as 'Locked Screen'")
        check "Use as 'Locked Screen'"
        expect(page).to have_link("Current Locked Screen: #{new_landing_page.title}")
        click_on("Overwrite current locked screen")
        click_on("Update Page")
        expect(page).to have_current_path(admin_pages_path)
      end
    end

    context "when a Forem is public" do
      it "does not give admins the option to set a lock screen" do
        allow(ForemInstance).to receive(:private).and_return(false)
        visit edit_admin_page_path(new_landing_page.id)
        expect(page).not_to have_content("Use as 'Locked Screen'")
      end
    end
  end
end
