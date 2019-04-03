require "rails_helper"

describe "Reading list" do
  let!(:user) { create(:user) }

  before do
    sign_in user
  end

  context "without tags" do
    it "shows the reading list" do
      create_list(:reading_reaction, 3, user: user)
      visit "/readinglist"
      expect(page).to have_selector("#load-more-cta", visible: false)
    end

    context "when large readinglist" do
      before { create_list(:reading_reaction, 46, user: user) }

      it "shows the large reading list" do
        visit "/readinglist"
        expect(page).to have_selector("#load-more-cta", visible: true)
      end

      it "shows the large readinglist after user clicks the show more button" do
        visit "/readinglist"
        click_button("LOAD MORE POSTS")
        expect(page).to have_selector("#load-more-cta", visible: false)
      end
    end

    context "with tag selected" do
      let(:article) { create(:article, title: "Java development", tags: "productivity, development, java") }
      let(:article2) { create(:article, title: "My java oop", tags: "productivity, design, java") }
      let(:article3) { create(:article, title: "My tools", tags: "productivity, tools") }

      before do
        create(:reading_reaction, user: user, reactable: article)
        create(:reading_reaction, user: user, reactable: article2)
        create(:reading_reaction, user: user, reactable: article3)
        visit "/readinglist?t=java"
      end

      it "does not show load more button" do
        expect(page).to have_selector("#load-more-cta", visible: false)
      end
    end
  end
end
