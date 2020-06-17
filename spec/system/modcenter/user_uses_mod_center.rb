require "rails_helper"

RSpec.describe "Visits Mod Center", type: :system do
  let_it_be(:moderator) { create(:user, :trusted) }
  let_it_be(:non_moderator) { create(:user) }

  context "when moderator is signed in" do
    before do
      sign_in moderator
      visit "/mod"
    end

    it "shows the 'All topics' view initially", js: true do
      expect(page).to have_content("Mod Center")
      expect(page).to have_content("All topics")
    end

    it "shows the tag view when its link is clicked", js: true do
      find(".inbox-tags", match: :first).click

      expect(page).to have_content("#discuss")
    end
  end

  # context "when non-moderator is signed in" do

  # end

  # context "when user not signed in" do

  # end
end
