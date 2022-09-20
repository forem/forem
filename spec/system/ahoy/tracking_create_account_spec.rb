require "rails_helper"

RSpec.describe "Tracking 'Clicked on Create Account'" do
  context "when on the homepage" do
    let(:user) { create(:user) }
    # rubocop:disable RSpec/LetSetup
    # this is to ensure that we see "ca_feed_home_page" which appears
    # in a card after the fifth article
    let!(:articles) { create_list(:article, 6, user: user) }
    # rubocop:enable RSpec/LetSetup

    before do
      visit root_path
    end

    it "expects page to have the necessary tracking elements", :aggregate_failures do
      # rubocop:disable RSpec/Capybara/SpecificMatcher
      expect(page).to have_selector('a[data-tracking-id="ca_top_nav"]')
      expect(page).to have_selector('a[data-tracking-id="ca_left_sidebar_home_page"]')
      expect(page).to have_selector('a[data-tracking-id="ca_hamburger_home_page"]')
      expect(page).to have_selector('a[data-tracking-id="ca_feed_home_page"]')
      # rubocop:enable RSpec/Capybara/SpecificMatcher
    end

    it "tracks a click with the correct source", { js: true, aggregate_failures: true } do
      expect do
        find('[data-tracking-id="ca_top_nav"]').click
      end.to change(Ahoy::Event, :count).by(1)

      expect(Ahoy::Event.last.name).to eq("Clicked on Create Account")

      expect(Ahoy::Event.last.properties).to have_key("source")
      expect(Ahoy::Event.last.properties).to have_key("page")
      expect(Ahoy::Event.last.properties).to have_key("referrer")

      expect(Ahoy::Event.last.properties["source"]).to eq("top_navbar")
    end
  end

  context "when tracking through the modal" do
    it "adds an ahoy event", { js: true } do
      article = create(:article, user: create(:user))
      visit article.path
      find(".follow-action-button").click

      expect do
        find(".js-global-signup-modal__create-account").click
      end.to change(Ahoy::Event, :count).by(1)

      expect(page).to have_current_path("/enter?state=new-user")
      expect(Ahoy::Event.last.name).to eq("Clicked on Create Account")
      expect(Ahoy::Event.last.properties).to have_key("source")
      expect(Ahoy::Event.last.properties).to have_key("page")
      expect(Ahoy::Event.last.properties).to have_key("secondary_source")
      expect(Ahoy::Event.last.properties).to have_key("trigger")
      expect(Ahoy::Event.last.properties).to have_key("referrer")
    end
  end
end
