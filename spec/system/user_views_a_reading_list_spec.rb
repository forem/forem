require "rails_helper"

RSpec.describe "Reading list", type: :system do
  let!(:user) { create(:user) }

  before do
    sign_in user
  end

  context "without tags" do
    context "when large readinglist" do
      before { create_list(:reading_reaction, 46, user: user) }

      it "shows the large reading list" do
        visit "/readinglist"
        expect(page).to have_selector("#reading-list", visible: true)
      end
    end
  end
end
