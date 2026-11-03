require "rails_helper"

RSpec.describe "Tracking 'Clicked on Create Account'" do
  context "when on the homepage" do
    before { visit root_path }

    it "has the necessary initial tracking elements", :aggregate_failures do
      expect(page).to have_css('a[data-tracking-id="ca_top_nav"][data-tracking-source="top_navbar"]')
      expect(page).to have_css('a[data-tracking-id="ca_left_sidebar_home_page"][data-tracking-source="left_sidebar"]')
    end

    it "has the create account tracking element in the hamburger", :js do
      Capybara.current_session.driver.resize(425, 694)
      first(".js-hamburger-trigger").click
      expect(page).to have_css('a[data-tracking-id="ca_hamburger_home_page"]')
    end
  end
end
