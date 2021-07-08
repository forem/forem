require "rails_helper"

RSpec.describe "User visits articles by timeframe", type: :system do
  let(:author) { create(:user) }
  let!(:article) { create(:article, user: author, published_at: Time.current) }
  let!(:days_old_article) { create(:article, user: author, published_at: 2.days.ago) }
  let!(:weeks_old_article) { create(:article, user: author, published_at: 2.weeks.ago) }
  let!(:months_old_article) { create(:article, user: author, published_at: 2.months.ago) }
  let!(:years_old_article) { create(:article, user: author, published_at: 2.years.ago) }

  def shows_correct_articles_count(count)
    expect(page).to have_selector(".crayons-story", visible: :visible, count: count)
  end

  def shows_correct_articles_count_via_xpath(count)
    expect(page).to have_xpath(
      "//article[contains(@class, 'crayons-story') and not(contains(@class, 'crayons-story--featured'))]",
      count: count,
    )
  end

  def shows_main_article
    expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
  end

  context "when user hasn't logged in" do
    context "when viewing articles for week" do
      before { visit "/top/week" }

      it "shows correct articles", :aggregate_failures do
        shows_correct_articles_count(2)
        shows_main_article
        within("#main-content") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
        end
      end
    end

    context "when viewing articles for month" do
      before { visit "/top/month" }

      it "shows correct articles", :aggregate_failures do
        shows_correct_articles_count(3)
        shows_main_article

        within("#main-content") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
        end
      end
    end

    context "when viewing articles for year" do
      before { visit "/top/year" }

      it "shows correct articles", :aggregate_failures do
        shows_correct_articles_count(4)
        shows_main_article

        within("#main-content") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
        end
      end
    end

    context "when viewing articles for infinity" do
      before { visit "/top/infinity" }

      it "shows correct articles and cta count", :aggregate_failures do
        shows_correct_articles_count(5)
        shows_main_article
        expect(page).to have_selector(".authentication-feed__card", count: 1)

        within("#main-content") do
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

      it "shows correct articles and cta-count", :aggregate_failures do
        shows_correct_articles_count(5)
        shows_main_article
        expect(page).to have_selector(".authentication-feed__card", count: 1)

        within("#main-content") do
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

    it "shows correct articles", :aggregate_failures do
      shows_correct_articles_count_via_xpath(1)
      shows_main_article

      within("#main-content") do
        expect(page).to have_text(article.title)
        expect(page).to have_text(days_old_article.title)
      end
    end

    context "when viewing articles for month" do
      before { visit "/top/month" }

      it "shows correct articles", :aggregate_failures do
        shows_correct_articles_count_via_xpath(2)
        shows_main_article

        within("#main-content") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
        end
      end
    end

    context "when viewing articles for year" do
      before { visit "/top/year" }

      it "shows correct articles", :aggregate_failures do
        shows_correct_articles_count_via_xpath(3)
        shows_main_article

        within("#main-content") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
        end
      end
    end

    context "when viewing articles for infinity" do
      before { visit "/top/infinity" }

      it "shows correct articles", :aggregate_failures do
        shows_correct_articles_count_via_xpath(4)
        shows_main_article

        within("#main-content") do
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

      it "shows correct articles", :aggregate_failures do
        shows_correct_articles_count_via_xpath(4)
        shows_main_article

        within("#main-content") do
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
