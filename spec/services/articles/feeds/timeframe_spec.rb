require "rails_helper"

RSpec.describe Articles::Feeds::Timeframe, type: :service do
  let!(:hot_article) do
    create(:article, :past, hotness_score: 1000, score: 1000, past_published_at: 3.hours.ago, user: create(:user))
  end
  let!(:low_scoring_article) { create(:article, score: -1000) }
  let!(:moderately_high_scoring_article) { create(:article, score: 20) }
  let!(:month_old_article) { create(:article, :past, past_published_at: 1.month.ago) }

  it "returns correct articles ordered by score", :aggregate_failures do
    result = described_class.call("week")
    expect(result.slice(0, 2)).to eq [hot_article, moderately_high_scoring_article]
    expect(result).not_to include(low_scoring_article)
    expect(result).not_to include(month_old_article)
  end

  it "returns low scoring articles if lower score is passed" do
    result = described_class.call("week", minimum_score: -1001)
    expect(result).to include(low_scoring_article)
  end
end
