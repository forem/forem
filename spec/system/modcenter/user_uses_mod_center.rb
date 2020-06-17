require "rails_helper"

RSpec.describe "Visits Mod Center", type: :system do
  let_it_be(:moderator) { create(:user, :trusted) }
  let_it_be(:non_moderator) { create(:user) }

  context "when moderator is signed in" do
    before do
      sign_in moderator
      visit "/mod"
    end

    it "shows the 'All topics' view", js: true, percy: true do
      Percy.snapshot(page, name: "Moderators: Visits Mod Center")

      expect(page).to have_content("Mod Center")
      expect(page).to have_content("All topics")
    end
  end

  # context "when non-moderator is signed in" do

  # end

  # context "when user not signed in" do

  # end
end
