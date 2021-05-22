require "rails_helper"

RSpec.describe Users::SuggestRecent, type: :service do
  let(:user) { create(:user) }
  let(:suggester) { described_class.new(user) }

  it "does not include calling user" do
    create_list(:user, 3)
    expect(suggester.suggest).not_to include(user)
  end

  context "with cached_followed_tags" do
    it "returns recent producers" do
      articles = create_list(:article, 3, score: 10)
      article = articles.last
      article.update(score: 100)
      allow(user).to receive(:decorate).and_return(user)
      allow(user).to receive(:cached_followed_tag_names).and_return(["html"])

      suggested_users = suggester.suggest
      expect(suggested_users.size).to eq(1)
      expect(suggested_users.map(&:id)).to include(article.user_id)
    end
  end

  context "without cached_followed_tags" do
    it "returns recent_commenters and recent top producers" do
      productive_user = create(:user, comments_count: 1, articles_count: 1)
      unproductive_user = create(:user, comments_count: 0, articles_count: 0)

      suggested_users = suggester.suggest
      expect(suggested_users.size).to eq(1)
      expect(suggested_users.map(&:id)).to include(productive_user.id)
      expect(suggested_users.map(&:id)).not_to include(unproductive_user.id)
    end
  end
end
