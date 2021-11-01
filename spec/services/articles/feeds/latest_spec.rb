require "rails_helper"

RSpec.describe Articles::Feeds::Latest, type: :service do
  let!(:hot_article) do
    create(:article, hotness_score: 1000, score: 1000, published_at: 3.hours.ago, user: create(:user))
  end
  let!(:newest_article) { create(:article, published_at: 1.hour.ago) }
  let!(:month_old_article) { create(:article, published_at: 1.month.ago) }
  let!(:low_scoring_article) { create(:article, score: -1000) }

  it "returns articles ordered by publishing date descending" do
    result = described_class.call
    expect(result).to eq [newest_article, hot_article, month_old_article]
  end

  it "only returns articles with scores above the minumum" do
    expect(described_class.call).not_to include(low_scoring_article)
  end
end
