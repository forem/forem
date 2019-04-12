require "rails_helper"

RSpec.describe "User visits a homepage", type: :system do
  let!(:article) { create(:article, reactions_count: 12, featured: true) }
  let!(:article2) { create(:article, reactions_count: 20, featured: true) }
  let!(:bad_article) { create(:article, reactions_count: 0) }
  let!(:user) { create(:user) }

  context "when no options specified" do
    before { visit "/" }

    it "shows the main article" do
      expect(page).to have_selector(".big-article", visible: true)
    end

    it "shows correct articles" do
      article.update_column(:score, 15)
      article2.update_column(:score, 15)
      expect(page).to have_selector(".single-article", count: 2)
      expect(page).to have_text(article.title)
      expect(page).to have_text(article2.title)
      expect(page).not_to have_text(bad_article.title)
    end
  end

  context "when more_articles" do
    before do
      articles = create_list(:article, 3, reactions_count: 30, featured: true)
      articles.each { |a| a.update_column(:score, 31) }
    end

    context "when unauthorized" do
      before { visit "/" }

      include_examples "shows the sign_in invitation"
    end

    context "when signed in" do
      before do
        sign_in user
        visit "/"
      end

      include_examples "no sign_in invitation"
    end

    describe "meta tags" do
      before { visit "/" }

      it "contains the qualified community name in og:title" do
        selector = "meta[property='og:title'][content='#{community_qualified_name}']"
        expect(page).to have_selector(selector, visible: false)
      end

      it "contains the qualified community name in og:site_name" do
        selector = "meta[property='og:site_name'][content='#{community_qualified_name}']"
        expect(page).to have_selector(selector, visible: false)
      end

      it "contains the qualified community name in twitter:title" do
        selector = "meta[name='twitter:title'][content='#{community_qualified_name}']"
        expect(page).to have_selector(selector, visible: false)
      end
    end
  end
end
