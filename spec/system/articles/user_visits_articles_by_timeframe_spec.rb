require "rails_helper"

RSpec.describe "User visits articles by timeframe", type: :system do
  let(:author) { create(:user) }
  let!(:article) { create(:article, user: author, published_at: Time.current) }
  let!(:days_old_article) { create(:article, user: author, published_at: 2.days.ago) }
  let!(:weeks_old_article) { create(:article, user: author, published_at: 2.weeks.ago) }
  let!(:months_old_article) { create(:article, user: author, published_at: 2.months.ago) }
  let!(:years_old_article) { create(:article, user: author, published_at: 2.years.ago) }

  context "when user hasn't logged in" do
    context "when viewing articles for week" do
      before { visit "/top/week" }

      it "shows correct articles count" do
        expect(page).to have_selector(".single-article-small-pic", count: 1)
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true, count: 1)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
        end
      end
    end

    context "when viewing articles for month" do
      before { visit "/top/month" }

      it "shows correct articles count" do
        expect(page).to have_selector(".single-article-small-pic", count: 2)
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true, count: 1)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
        end
      end
    end

    context "when viewing articles for year" do
      before { visit "/top/year" }

      it "shows correct articles count" do
        expect(page).to have_selector(".single-article-small-pic", count: 3)
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true, count: 1)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
        end
      end
    end

    context "when viewing articles for infinity" do
      before { visit "/top/infinity" }

      it "shows correct articles and cta count" do
        expect(page).to have_selector(".single-article-small-pic", count: 5)
        expect(page).to have_selector(".feed-cta", count: 1)
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true, count: 1)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
          expect(page).to have_text(years_old_article.title)
        end
      end
    end

    context "when viewing articles for latest" do
      before { visit "/latest" }

      it "shows correct articles and cta count" do
        expect(page).to have_selector(".single-article-small-pic", count: 5)
        expect(page).to have_selector(".feed-cta", count: 1)
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true, count: 1)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
          expect(page).to have_text(years_old_article.title)
        end
      end
    end
  end

  context "when user has logged in", js: true do
    let(:user) { create(:user) }

    before do
      sign_in user
      visit "/top/week"
    end

    it "shows correct articles count" do
      expect(page).to have_selector(".single-article-small-pic", count: 1)
    end

    it "shows the main article" do
      expect(page).to have_selector(".big-article", visible: true, count: 1)
    end

    it "shows the correct articles" do
      within("#articles-list") do
        expect(page).to have_text(article.title)
        expect(page).to have_text(days_old_article.title)
      end
    end

    context "when viewing articles for month" do
      before { visit "/top/month" }

      it "shows correct articles count" do
        expect(page).to have_selector(".single-article-small-pic", count: 2)
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true, count: 1)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
        end
      end
    end

    context "when viewing articles for year" do
      before { visit "/top/year" }

      it "shows correct articles count" do
        expect(page).to have_selector(".single-article-small-pic", count: 3)
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true, count: 1)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
        end
      end
    end

    context "when viewing articles for infinity" do
      before { visit "/top/infinity" }

      it "shows correct articles count" do
        expect(page).to have_selector(".single-article-small-pic", count: 4)
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true, count: 1)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
          expect(page).to have_text(years_old_article.title)
        end
      end
    end

    context "when viewing articles for latest" do
      before { visit "/latest" }

      it "shows correct articles" do
        expect(page).to have_selector(".single-article-small-pic", count: 4)
      end

      it "shows the main article" do
        expect(page).to have_selector(".big-article", visible: true, count: 1)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
          expect(page).to have_text(years_old_article.title)
        end
      end
    end
  end
end
