require "rails_helper"

RSpec.describe "User visits the videos page", type: :system do
  context "when user hasn't logged in" do
    before { visxit "/videos" }

    describe "meta tags" do
      xit "contains the qualified community name in og:site_name", js: true, percy: true do
        selector = "meta[property='og:site_name'][content='#{community_qualified_name}']"

        Percy.snapshot(page, name: "Videos: /videos renders")

        expect(page).to have_selector(selector, visible: :hidden)
      end
    end
  end
end
