require "rails_helper"

RSpec.describe Articles::Feeds::Latest, type: :service do
  let!(:hot_article) do
    create(:article, :past, hotness_score: 1000, score: 1000, past_published_at: 3.hours.ago, user: create(:user))
  end
  let!(:newest_article) { create(:article, :past, past_published_at: 1.hour.ago) }
  let!(:month_old_article) { create(:article, :past, past_published_at: 1.month.ago) }
  let!(:low_scoring_article) { create(:article, score: -1000) }

  it "returns articles ordered by publishing date descending" do
    result = described_class.call
    expect(result).to eq [newest_article, hot_article, month_old_article]
  end

  it "only returns articles with scores above the minimum" do
    expect(described_class.call).not_to include(low_scoring_article)
  end

  it "loads the feed without querying reactions" do
    create(:reaction, reactable: newest_article, category: "like")
    reaction_queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      reaction_queries << payload[:sql] if payload[:sql].include?('"reactions"')
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { described_class.call.load }

    expect(reaction_queries).to be_empty
  end

  it "still returns the reaction categories of each article" do
    create(:reaction, reactable: newest_article, category: "like")

    story = described_class.call.find { |article| article.id == newest_article.id }

    expect(story.public_reaction_categories.map(&:slug)).to eq([:like])
  end
end
