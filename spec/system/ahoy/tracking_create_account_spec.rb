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

    it "has the necessary initial tracking elements", :aggregate_failures do
      expect(page).to have_selector('a[data-tracking-id="ca_top_nav"]')
      expect(page).to have_selector('a[data-tracking-id="ca_left_sidebar_home_page"]')
      expect(page).to have_selector('a[data-tracking-id="ca_feed_home_page"]')
    end

    it "has the create account tracking element in the hamburger", { aggregate_failures: true, js: true } do
      Capybara.current_session.driver.resize(425, 694)
      first(".js-hamburger-trigger").click
      expect(page).to have_selector('a[data-tracking-id="ca_hamburger_home_page"]')
    end

    it "tracks a click with the correct source", { aggregate_failures: true, js: true } do
      expect do
        find('[data-tracking-id="ca_top_nav"]').click
      end.to change(Ahoy::Event, :count).by(1)

      ahoy_event = Ahoy::Event.find_by(name: "Clicked on Create Account")
      expect(ahoy_event).to be_present
      expect(ahoy_event.properties).to have_key("source")
      expect(ahoy_event.properties).to have_key("page")
      expect(ahoy_event.properties).to have_key("version")

      expect(ahoy_event.properties["source"]).to eq("top_navbar")
    end
  end

  context "when tracking through the modal" do
    it "adds an ahoy event", { aggregate_failures: true, js: true } do
      article = create(:article, user: create(:user))
      visit article.path
      find(".follow-action-button").click
      find(".js-global-signup-modal__create-account").click

      expect(page).to have_current_path("/enter?state=new-user")
      ahoy_event = Ahoy::Event.find_by(name: "Clicked on Create Account")
      expect(ahoy_event).to be_present
      expect(ahoy_event.properties).to have_key("source")
      expect(ahoy_event.properties).to have_key("page")
      expect(ahoy_event.properties).to have_key("referring_source")
      expect(ahoy_event.properties).to have_key("trigger")
      expect(ahoy_event.properties).to have_key("version")
    end
  end
end
