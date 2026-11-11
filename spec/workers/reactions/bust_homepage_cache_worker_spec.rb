require "rails_helper"

RSpec.describe Reactions::BustHomepageCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article, featured: true) }
    let(:worker) { subject }

    before do
      allow(EdgeCache::PurgeByKey).to receive(:call)
    end

    it "busts the homepage surrogate key when reactable is a featured Article" do
      reaction = create(:reaction, reactable: article, user: user)
      RSpec::Mocks.space.proxy_for(EdgeCache::PurgeByKey).reset
      allow(EdgeCache::PurgeByKey).to receive(:call)

      worker.perform(reaction.id)

      expect(EdgeCache::PurgeByKey).to have_received(:call).with("main_app_home_page", fallback_paths: "/").once
    end

    it "doesn't load the article or bust the homepage when the article is not featured" do
      unfeatured = create(:article, featured: false)
      reaction = create(:reaction, reactable: unfeatured, user: user)
      RSpec::Mocks.space.proxy_for(EdgeCache::PurgeByKey).reset
      allow(EdgeCache::PurgeByKey).to receive(:call)
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }

      expect do
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { worker.perform(reaction.id) }
      end.not_to(change { unfeatured.reload.updated_at })

      expect(queries.grep(/SELECT "articles"\.\*/)).to be_empty
      expect(EdgeCache::PurgeByKey).not_to have_received(:call)
    end

    it "touches the featured article it busts" do
      reaction = create(:reaction, reactable: article, user: user)

      expect { worker.perform(reaction.id) }.to(change { article.reload.updated_at })
    end

    it "doesn't bust the homepage cache when reactable is a Comment" do
      comment = create(:comment, commentable: article)
      comment_reaction = create(:reaction, reactable: comment, user: user)
      RSpec::Mocks.space.proxy_for(EdgeCache::PurgeByKey).reset
      allow(EdgeCache::PurgeByKey).to receive(:call)

      worker.perform(comment_reaction.id)

      expect(EdgeCache::PurgeByKey).not_to have_received(:call)
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end
  end
end
