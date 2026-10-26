require "rails_helper"

RSpec.describe UpdateUserInterestEmbeddingWorker, type: :worker do
  let(:user) { create(:user) }
  let!(:user_activity) { create(:user_activity, user: user) }
  let(:article) { create(:article) }

  describe "#perform" do
    it "sets the embedding directly if the user currently has none" do
      article.update_column(:semantic_embedding, Array.new(768, 1.0))
      user_activity.update_column(:interest_embedding, nil)

      described_class.new.perform(user.id, article.id)

      expect(user_activity.reload.interest_embedding).to eq(Array.new(768, 1.0))
    end

    it "blends the embedding using EMA if the user already has one, using provided blend factor" do
      article.update_column(:semantic_embedding, Array.new(768) { |i| i.even? ? 1.0 : 0.0 })
      user_activity.update_column(:interest_embedding, Array.new(768) { |i| i.even? ? 0.0 : 1.0 })

      # Blend factor is 0.3.
      # new_x = 0.0 * 0.7 + 1.0 * 0.3 = 0.3
      # new_y = 1.0 * 0.7 + 0.0 * 0.3 = 0.7
      
      described_class.new.perform(user.id, article.id, 0.3)

      result = user_activity.reload.interest_embedding.to_a
      expect(result[0]).to be_within(0.001).of(0.3)
      expect(result[1]).to be_within(0.001).of(0.7)
    end

    it "loads only the article's id and embedding columns" do
      article.update_column(:semantic_embedding, Array.new(768, 1.0))
      article_queries = []
      callback = lambda do |*, payload|
        article_queries << payload[:sql] if payload[:sql].include?('FROM "articles"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.new.perform(user.id, article.id)
      end

      expect(article_queries.size).to eq(1)
      expect(article_queries.first).not_to include('"articles".*')
      expect(user_activity.reload.interest_embedding).to eq(Array.new(768, 1.0))
    end

    it "does nothing if the article does not exist" do
      user_activity.update_column(:interest_embedding, Array.new(768, 1.0))

      described_class.new.perform(user.id, Article.maximum(:id).to_i + 1)

      expect(user_activity.reload.interest_embedding).to eq(Array.new(768, 1.0))
    end

    it "does nothing if the article has no embedding" do
      article.update_column(:semantic_embedding, nil)
      user_activity.update_column(:interest_embedding, Array.new(768, 1.0))

      described_class.new.perform(user.id, article.id)

      expect(user_activity.reload.interest_embedding).to eq(Array.new(768, 1.0))
    end
  end
end
