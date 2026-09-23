require "rails_helper"

RSpec.describe Articles::Feeds::Curated do
  let(:leader) { create(:user) }
  let(:user) { create(:user) }

  describe ".call" do
    it "returns only favorited articles" do
      favorited_article = create(:article, favorited_by_user: leader, favorited_at: Time.current)
      unfavorited_article = create(:article)

      results = described_class.call

      expect(results).to include(favorited_article)
      expect(results).not_to include(unfavorited_article)
    end

    it "orders articles by favorited_at descending" do
      first_favorited = create(:article, favorited_by_user: leader, favorited_at: 2.hours.ago)
      recently_favorited = create(:article, favorited_by_user: leader, favorited_at: 10.minutes.ago)

      results = described_class.call

      expect(results.to_a).to eq([recently_favorited, first_favorited])
    end

    it "filters out antifollowed tags for the given user" do
      allow(user).to receive(:cached_antifollowed_tag_names).and_return(["ruby"])

      favorited_tagged = create(:article, favorited_by_user: leader, favorited_at: Time.current, tags: "ruby")
      favorited_other = create(:article, favorited_by_user: leader, favorited_at: 1.hour.ago, tags: "javascript")

      results = described_class.call(user: user)

      expect(results).to include(favorited_other)
      expect(results).not_to include(favorited_tagged)
    end

    it "paginates results" do
      create_list(:article, 3, favorited_by_user: leader, favorited_at: Time.current)

      results = described_class.call(number_of_articles: 2, page: 1)

      expect(results.count).to eq(2)
    end
  end
end
