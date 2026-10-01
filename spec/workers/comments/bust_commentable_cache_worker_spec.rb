require "rails_helper"

RSpec.describe Comments::BustCommentableCacheWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", ["Article", 1]

  describe "#perform" do
    let(:worker) { subject }

    before { allow(EdgeCache::BustComment).to receive(:call) }

    it "busts the commentable's comment caches" do
      article = create(:article)

      worker.perform("Article", article.id)

      expect(EdgeCache::BustComment).to have_received(:call).with(article)
    end

    it "busts podcast episode commentables" do
      episode = create(:podcast_episode)

      worker.perform("PodcastEpisode", episode.id)

      expect(EdgeCache::BustComment).to have_received(:call).with(episode)
    end

    it "does nothing when the commentable no longer exists" do
      worker.perform("Article", -1)

      expect(EdgeCache::BustComment).not_to have_received(:call)
    end

    it "does nothing for types that aren't commentable" do
      user = create(:user)

      worker.perform("User", user.id)

      expect(EdgeCache::BustComment).not_to have_received(:call)
    end
  end
end
