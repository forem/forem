require "rails_helper"

RSpec.describe "User visits a homepage", type: :system do
  let!(:article) { create(:article, reactions_count: 12, featured: true, user: create(:user, profile_image: nil)) }
  let!(:article2) { create(:article, reactions_count: 20, featured: true, user: create(:user, profile_image: nil)) }
  let!(:timestamp) { "2019-03-04T10:00:00Z" }
  let(:published_datetime) { Time.zone.parse(timestamp) }
  let(:published_date) { published_datetime.strftime("%b %e").gsub("  ", " ") }

  context "when no options specified" do
    context "when main featured article" do
      before do
        article.update_column(:published_at, published_datetime)
        article2.update_column(:published_at, published_datetime)
        visit "/"
      end

      it "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible)
      end

      # Regression test for https://github.com/forem/forem/pull/12724
      it "does not display a comment count of 0", js: true do
        expect(page).to have_text("Add Comment")
        expect(page).not_to have_text("0 #{I18n.t('core.comment').downcase}s")
        article.update_column(:comments_count, 50)
        visit "/"
        expect(page).to have_text(/50\s*#{I18n.t("core.comment").downcase}s/)
      end

      it "shows the main article readable date and time", js: true do
        expect(page).to have_selector(".crayons-story--featured time", text: published_date)
        selector = ".crayons-story--featured time[datetime='#{timestamp}']"
        expect(page).to have_selector(selector)
      end
    end

    context "when all other articles" do
      before do
        article.update_columns(score: 15, published_at: published_datetime)
        article2.update_columns(score: 15, published_at: published_datetime)
        visit "/"
      end

      it "shows correct articles " do
        expect(page).to have_selector(".crayons-story", count: 2)
        expect(page).to have_text(article.title)
        expect(page).to have_text(article2.title)
      end

      it "shows all articles' dates and times", js: true do
        expect(page).to have_selector(".crayons-story time", text: published_date, count: 2)
        selector = ".crayons-story time[datetime='#{timestamp}']"
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
        selector = "meta[property='og:title'][content='#{community_name}']"
        expect(page).to have_selector(selector, visible: :hidden)
      end

      it "contains the qualified community name in og:site_name" do
        selector = "meta[property='og:site_name'][content='#{community_name}']"
        expect(page).to have_selector(selector, visible: :hidden)
      end

      it "contains the qualified community name in twitter:title" do
        selector = "meta[name='twitter:title'][content='#{community_name}']"
        expect(page).to have_selector(selector, visible: :hidden)
      end
    end
  end
end
