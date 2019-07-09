require "rails_helper"

RSpec.describe Collection, type: :model do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, :with_articles, user: user) }

  describe "when a single article in collection is updated" do
    it "touches all articles in the collection" do
      random_article = collection.articles.sample
      expect { random_article.touch }.to(change { collection.articles.map(&:updated_at) })
    end
  end
end
