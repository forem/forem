require "rails_helper"

RSpec.describe Articles::Feeds::Basic, type: :service do
  let(:user) { create(:user) }
  let!(:feed) { described_class.new(user: user, number_of_articles: 100, page: 1) }
  let!(:article) { create(:article) }
  let!(:hot_story) { create(:article, hotness_score: 1000, score: 1000, published_at: 3.hours.ago) }
  let!(:old_story) { create(:article, published_at: 3.days.ago) }
  let!(:low_scoring_article) { create(:article, score: -1000) }
  let!(:month_old_story) { create(:article, published_at: 1.month.ago) }

  xit "returns articles in approximately published order" do
    result = feed.feed
    expect(result.first).to eq hot_story
    expect(result.second).to eq article
    expect(result.third).to eq old_story
    expect(result.last).to eq month_old_story
  end

  it "does not include low quality" do
    result = feed.feed
    expect(result).not_to include(low_scoring_article)
  end
end
