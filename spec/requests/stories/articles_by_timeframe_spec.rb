require "rails_helper"

RSpec.describe "Stories::ArticlesByTimeframe" do
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

  def assert_timeframe_html(path, expected_story_count:, expected_articles:)
    get path
    expect(response).to have_http_status(:ok)

    doc = Nokogiri::HTML(response.body)
    expect(doc.css(".crayons-story").count).to eq(expected_story_count)
    expect(doc.css(".crayons-story--featured").count).to eq(1)

    main_text = doc.at_css("#main-content").text
    expected_articles.each do |expected_article|
      expect(main_text).to include(expected_article.title)
    end
  end

  it "renders the expected articles for all timeframe tabs for logged out users", :aggregate_failures do
    assert_timeframe_html(
      "/top/week",
      expected_story_count: 2,
      expected_articles: [article, days_old_article],
    )

    assert_timeframe_html(
      "/top/month",
      expected_story_count: 3,
      expected_articles: [article, days_old_article, weeks_old_article],
    )

    assert_timeframe_html(
      "/top/year",
      expected_story_count: 4,
      expected_articles: [article, days_old_article, weeks_old_article, months_old_article],
    )

    assert_timeframe_html(
      "/top/infinity",
      expected_story_count: 5,
      expected_articles: [article, days_old_article, weeks_old_article, months_old_article, years_old_article],
    )

    assert_timeframe_html(
      "/latest",
      expected_story_count: 6,
      expected_articles: [article, days_old_article, weeks_old_article, months_old_article, years_old_article],
    )
  end

  it "returns the expected articles for all timeframe feeds for signed in users", :aggregate_failures do
    sign_in create(:user)

    {
      week: [article, days_old_article],
      month: [article, days_old_article, weeks_old_article],
      year: [article, days_old_article, weeks_old_article, months_old_article],
      infinity: [article, days_old_article, weeks_old_article, months_old_article, years_old_article],
      latest: [article, days_old_article, weeks_old_article, months_old_article, years_old_article]
    }.each do |timeframe, expected_articles|
      get timeframe_stories_feed_path(timeframe)
      expect(response).to have_http_status(:ok)

      titles = response.parsed_body.pluck("title")
      expect(titles).to match_array(expected_articles.map(&:title))
    end
  end
end
