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
      before { visxit "/top/week" }

      xit "shows correct articles count" do
        expect(page).to have_selector(".crayons-story", visible: :visible, count: 2)
      end

      xit "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
      end

      xit "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
        end
      end
    end

    context "when viewing articles for month" do
      before { visxit "/top/month" }

      xit "shows correct articles count" do
        expect(page).to have_selector(".crayons-story", visible: :visible, count: 3)
      end

      xit "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
      end

      xit "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
        end
      end
    end

    context "when viewing articles for year" do
      before { visxit "/top/year" }

      xit "shows correct articles count" do
        expect(page).to have_selector(".crayons-story", visible: :visible, count: 4)
      end

      xit "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
      end

      xit "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
        end
      end
    end

    context "when viewing articles for infinity" do
      before { visxit "/top/infinity" }

      xit "shows correct articles and cta count" do
        expect(page).to have_selector(".crayons-story", visible: :visible, count: 5)
        expect(page).to have_selector(".feed-cta", count: 1)
      end

      xit "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
      end

      xit "shows the correct articles" do
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
      before { visxit "/latest" }

      xit "shows correct articles and cta count" do
        expect(page).to have_selector(".crayons-story", visible: :visible, count: 5)
        expect(page).to have_selector(".feed-cta", count: 1)
      end

      xit "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
      end

      xit "shows the correct articles" do
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

  context "when user has logged in", js: true, elasticsearch: "FeedContent" do
    let(:user) { create(:user) }

    before do
      sign_in user
      visxit "/top/week"
    end

    xit "shows correct articles count" do
      expect(page).to have_xpath("//article[contains(@class, 'crayons-story') and contains(@class, 'false')]", count: 1)
    end

    xit "shows the main article" do
      expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
    end

    xit "shows the correct articles" do
      within("#articles-list") do
        expect(page).to have_text(article.title)
        expect(page).to have_text(days_old_article.title)
      end
    end

    context "when viewing articles for month" do
      before { visxit "/top/month" }

      xit "renders the page", percy: true do
        Percy.snapshot(page, name: "Articles: /top/month")
      end

      xit "shows correct articles count" do
        expect(page).to have_xpath("//article[contains(@class, 'crayons-story') and contains(@class, 'false')]", count: 2)
      end

      xit "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
      end

      xit "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
        end
      end
    end

    context "when viewing articles for year" do
      before { visxit "/top/year" }

      xit "shows correct articles count" do
        expect(page).to have_xpath("//article[contains(@class, 'crayons-story') and contains(@class, 'false')]", count: 3)
      end

      xit "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
      end

      xit "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(days_old_article.title)
          expect(page).to have_text(weeks_old_article.title)
          expect(page).to have_text(months_old_article.title)
        end
      end
    end

    context "when viewing articles for infinity" do
      before { visxit "/top/infinity" }

      xit "shows correct articles count" do
        expect(page).to have_xpath("//article[contains(@class, 'crayons-story') and contains(@class, 'false')]", count: 4)
      end

      xit "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
      end

      xit "shows the correct articles" do
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
      before { visxit "/latest" }

      xit "renders the page", percy: true do
        Percy.snapshot(page, name: "Articles: /latest")
      end

      xit "shows correct articles" do
        expect(page).to have_xpath("//article[contains(@class, 'crayons-story') and contains(@class, 'false')]", count: 4)
      end

      xit "shows the main article" do
        expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
      end

      xit "shows the correct articles" do
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
