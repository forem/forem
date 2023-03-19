require "rails_helper"

# rubocop:disable RSpec/ExampleLength
RSpec.describe "User visits articles by timeframe", js: true do
  let(:author) { create(:user) }
  let(:minimum_score) { Settings::UserExperience.home_feed_minimum_score + 1 }
  let!(:article) { create(:article, score: minimum_score, user: author) }
  let!(:days_old_article) { create(:article, :past, past_published_at: 2.days.ago, score: minimum_score, user: author) }
  let!(:weeks_old_article) do
    create(:article, :past, past_published_at: 2.weeks.ago, score: minimum_score, user: author)
  end
  let!(:months_old_article) do
    create(:article, :past, past_published_at: 2.months.ago, score: minimum_score, user: author)
  end
  let!(:years_old_article) do
    create(:article, :past, past_published_at: 2.years.ago, score: minimum_score, user: author)
  end

  before do
    Timecop.freeze(Time.current)
  end

  after do
    Timecop.return
  end

  def shows_correct_articles_count(count)
    expect(page).to have_selector(".crayons-story", visible: :all, count: count)
  end

  def shows_main_article
    expect(page).to have_selector(".crayons-story--featured", visible: :visible, count: 1)
  end

  it "shows correct articles for all tabs for logged out users", :aggregate_failures do
    visit "/top/week"

    shows_correct_articles_count(2)
    shows_main_article
    within("#main-content") do
      expect(page).to have_text(article.title)
      expect(page).to have_text(days_old_article.title)
    end

    visit "/top/month"

    shows_correct_articles_count(3)
    shows_main_article

    within("#main-content") do
      expect(page).to have_text(article.title)
      expect(page).to have_text(days_old_article.title)
      expect(page).to have_text(weeks_old_article.title)
    end

    visit "/top/year"
    shows_correct_articles_count(4)
    shows_main_article

    within("#main-content") do
      expect(page).to have_text(article.title)
      expect(page).to have_text(days_old_article.title)
      expect(page).to have_text(weeks_old_article.title)
      expect(page).to have_text(months_old_article.title)
    end

    visit "/top/infinity"

    shows_correct_articles_count(5)
    shows_main_article
    expect(page).to have_selector("#in-feed-cta", count: 1)

    within("#main-content") do
      expect(page).to have_text(article.title)
      expect(page).to have_text(days_old_article.title)
      expect(page).to have_text(weeks_old_article.title)
      expect(page).to have_text(months_old_article.title)
      expect(page).to have_text(years_old_article.title)
    end

    visit "/latest"
    shows_correct_articles_count(6)
    shows_main_article
    expect(page).to have_selector("#in-feed-cta", count: 1)

    within("#main-content") do
      expect(page).to have_text(article.title)
      expect(page).to have_text(days_old_article.title)
      expect(page).to have_text(weeks_old_article.title)
      expect(page).to have_text(months_old_article.title)
      expect(page).to have_text(years_old_article.title)
    end
  end

  it "shows correct articles for signed_in user", :aggregate_failures do
    sign_in create(:user)
    visit "/top/week"

    shows_correct_articles_count(2)
    shows_main_article
    within("#main-content") do
      expect(page).to have_text(article.title)
      expect(page).to have_text(days_old_article.title)
    end

    visit "/top/month"

    shows_correct_articles_count(3)
    shows_main_article
    within("#main-content") do
      expect(page).to have_text(article.title)
      expect(page).to have_text(days_old_article.title)
      expect(page).to have_text(weeks_old_article.title)
    end

    visit "/top/year"

    shows_correct_articles_count(4)
    shows_main_article
    within("#main-content") do
      expect(page).to have_text(article.title)
      expect(page).to have_text(days_old_article.title)
      expect(page).to have_text(weeks_old_article.title)
      expect(page).to have_text(months_old_article.title)
    end

    visit "/top/infinity"

    shows_correct_articles_count(5)
    shows_main_article
    within("#main-content") do
      expect(page).to have_text(article.title)
      expect(page).to have_text(days_old_article.title)
      expect(page).to have_text(weeks_old_article.title)
      expect(page).to have_text(months_old_article.title)
      expect(page).to have_text(years_old_article.title)
    end

    visit "/latest"

    shows_correct_articles_count(5)
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

# rubocop:enable RSpec/ExampleLength
