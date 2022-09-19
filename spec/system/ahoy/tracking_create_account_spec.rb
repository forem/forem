require "rails_helper"

RSpec.describe "Tracking 'Clicked on Create Account'" do
  context "when on the homepage" do
    let(:user) { create(:user) }

    before do
      visit root_path
      # this is to ensure that we see "ca_feed_home_page" which appears in a card after the fifth
      # article
      create_list(:article, 6, user: user)
    end

    it "expects page to have the necessary tracking elements" do
      visit root_path
      # rubocop:disable RSpec/Capybara/SpecificMatcher
      expect(page).to have_selector('a[data-tracking-id="ca_top_nav"]')
      expect(page).to have_selector('a[data-tracking-id="ca_left_sidebar_home_page"]')
      expect(page).to have_selector('a[data-tracking-id="ca_hamburger_home_page"]')
      expect(page).to have_selector('a[data-tracking-id="ca_feed_home_page"]')
      # rubocop:enable RSpec/Capybara/SpecificMatcher
    end

    it "tracks a click with the correct source", { js: true, aggregate_failures: true } do
      page.find('[data-tracking-id="ca_top_nav"]').click
      expect(Ahoy::Event.count).to eq(1)
      expect(Ahoy::Event.last.name).to eq("Clicked on Create Account")

      expect(Ahoy::Event.last.properties).to have_key("source")
      expect(Ahoy::Event.last.properties).to have_key("page")
      expect(Ahoy::Event.last.properties).to have_key("referrer")

      expect(Ahoy::Event.last.properties["source"]).to eq("top_navbar")
    end
  end
end
