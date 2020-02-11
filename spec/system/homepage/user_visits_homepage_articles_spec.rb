require "rails_helper"

RSpec.describe "User visits a homepage", type: :system do
  let!(:article) { create(:article, reactions_count: 12, featured: true) }
  let!(:article2) { create(:article, reactions_count: 20, featured: true) }
  let!(:timestamp) { "2019-03-04T10:00:00Z" }

  context "when no options specified" do
    context "when main featured article" do
      before do
        article.update_column(:published_at, Time.zone.parse(timestamp))
        article2.update_column(:published_at, Time.zone.parse(timestamp))
        visit "/"
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true)
      end

      it "shows the main article readable date", js: true do
        expect(page).to have_selector(".big-article time", text: "Mar 4")
      end

      it "embeds the main article published timestamp" do
        selector = ".big-article time[datetime='#{timestamp}']"
        expect(page).to have_selector(selector)
      end
    end

    context "when all other articles" do
      before do
        article.update_columns(score: 15, published_at: Time.zone.parse(timestamp))
        article2.update_columns(score: 15, published_at: Time.zone.parse(timestamp))
        visit "/"
      end

      it "shows correct articles " do
        expect(page).to have_selector(".single-article", count: 2)
        expect(page).to have_text(article.title)
        expect(page).to have_text(article2.title)
      end

      it "shows all articles dates", js: true do
        expect(page).to have_selector(".single-article time", text: "Mar 4", count: 2)
      end

      it "embeds all articles published timestamps" do
        selector = ".single-article time[datetime='#{timestamp}']"
        expect(page).to have_selector(selector, count: 2)
      end
    end
  end

  context "when more_articles" do
    before do
      articles = create_list(:article, 3, reactions_count: 30, featured: true)
      articles.each { |a| a.update_column(:score, 31) }
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
