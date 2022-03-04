require "rails_helper"

RSpec.describe "User visits the videos page", type: :system do
  context "when user hasn't logged in" do
    before { visit "/videos" }

    describe "meta tags" do
      it "contains the qualified community name in og:site_name", js: true do
        selector = "meta[property='og:site_name'][content='#{community_name}']"

        expect(page).to have_selector(selector, visible: :hidden)
      end

      it "contains the expected title tags" do
        expected_title = "Videos - #{community_name}"

        expect(page).to have_title(expected_title)
        expect(page).to have_selector("meta[property='og:title'][content='#{expected_title}']", visible: :hidden)
        expect(page).to have_selector("meta[name='twitter:title'][content='#{expected_title}']", visible: :hidden)
      end
    end
  end
end
