require "rails_helper"

RSpec.describe "Reading list", type: :system do
  let!(:user) { create(:user) }

  before do
    sign_in user
  end

  context "without tags" do
    context "when large reading list" do
      before { create_list(:reading_reaction, 46, user: user) }

      it "shows the large reading list", js: true, percy: true do
        visit "/readinglist"

        Percy.snapshot(page, name: "Viewing a reading list: shows a large list")

        expect(page).to have_selector("#reading-list", visible: :visible)
      end
    end
  end
end
