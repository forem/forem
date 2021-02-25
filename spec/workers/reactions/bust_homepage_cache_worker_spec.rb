require "rails_helper"

RSpec.describe Reactions::BustHomepageCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article, featured: true) }
    let(:worker) { subject }
    let(:cache_bust) { instance_double(EdgeCache::Bust) }

    before do
      allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
      allow(cache_bust).to receive(:call)
    end

    it "busts the homepage cache when reactable is an Article" do
      reaction = create(:reaction, reactable: article, user: user)

      worker.perform(reaction.id)

      expect(cache_bust).to have_received(:call).with("/").exactly(2).times
      expect(cache_bust).to have_received(:call).with("/?i=i")
      expect(cache_bust).to have_received(:call).with("?i=i")
    end

    it "doesn't bust the homepage cache when reactable is a Comment" do
      comment = create(:comment, commentable: article)
      comment_reaction = create(:reaction, reactable: comment, user: user)

      worker.perform(comment_reaction.id)

      expect(cache_bust).not_to have_received(:call).with("/")
      expect(cache_bust).not_to have_received(:call).with("/?i=i")
      expect(cache_bust).not_to have_received(:call).with("?i=i")
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end
  end
end
