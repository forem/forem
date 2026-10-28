require "rails_helper"

RSpec.describe "User visits the videos page" do
  context "when user hasn't logged in" do
    before { visit "/videos" }

    describe "meta tags" do
      it "contains the qualified community name in og:site_name and the expected title tags", :aggregate_failures do
        expected_title = "Videos - #{community_name}"

        expect(page).to have_css("meta[property='og:site_name'][content='#{community_name}']", visible: :hidden)
        expect(page).to have_title(expected_title)
        expect(page).to have_css("meta[property='og:title'][content='#{expected_title}']", visible: :hidden)
        expect(page).to have_css("meta[name='twitter:title'][content='#{expected_title}']", visible: :hidden)
      end
    end
  end
end
