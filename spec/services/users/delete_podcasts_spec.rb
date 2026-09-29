require "rails_helper"

RSpec.describe Users::DeletePodcasts do
  let!(:user) { create(:user) }
  let!(:podcast) { create(:podcast, creator: user) }

  before do
    create(:podcast_ownership, owner: user, podcast: podcast)
  end

  context "when podcast is owned by multiple users" do
    before do
      other_user = create(:user)
      create(:podcast_ownership, owner: other_user, podcast: podcast)
    end

    it "only removes ownership from the given user", :aggregate_failures do
      expect do
        expect do
          described_class.call(user)
        end.not_to change(Podcast, :count)
      end.to change(PodcastOwnership, :count).by(-1)
    end
  end

  context "when podcast is owned by one user" do
    it "removes ownership from the given user and deletes the podcast", :aggregate_failures do
      expect do
        expect do
          described_class.call(user)
        end.to change(Podcast, :count).by(-1)
      end.to change(PodcastOwnership, :count).by(-1)
    end

    it "busts the deleted podcast's cache in the background" do
      allow(EdgeCache::BustPodcast).to receive(:call)

      sidekiq_assert_enqueued_with(job: Podcasts::BustCacheWorker, args: [podcast.path]) do
        described_class.call(user)
      end
      expect(EdgeCache::BustPodcast).not_to have_received(:call)
    end
  end
end
