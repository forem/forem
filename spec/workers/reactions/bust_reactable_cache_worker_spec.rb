require "rails_helper"

RSpec.describe Reactions::BustReactableCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article) }
    let(:reaction) { create(:reaction, reactable: article, user: user) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment, user: user) }
    let(:worker) { subject }

    before do
      allow(EdgeCache::BustArticle).to receive(:call)
      allow(EdgeCache::PurgeByKey).to receive(:call)
    end

    it "busts the reactable article cache" do
      worker.perform(reaction.id)
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        user.profile_identity_record_key,
        fallback_paths: [user.path],
      )
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        Reaction.surrogate_key_for_article(article.id),
        fallback_paths: "/reactions?article_id=#{article.id}",
      )
    end

    it "busts the article if there were previously no reactions" do
      worker.perform(reaction.id)
      expect(EdgeCache::BustArticle).to have_received(:call)
    end

    it "does not bust the article if there were previously one reactions" do
      create(:reaction, reactable: article, user: create(:user))
      worker.perform(reaction.id)
      expect(EdgeCache::BustArticle).not_to have_received(:call)
    end

    it "busts the reactable comment cache" do
      worker.perform(comment_reaction.id)
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        user.profile_identity_record_key,
        fallback_paths: [user.path],
      )
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        Reaction.surrogate_key_for_commentable(article),
        fallback_paths: "/reactions?commentable_id=#{article.id}&commentable_type=Article",
      )
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end
  end
end
