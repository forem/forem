require "rails_helper"

RSpec.describe Reactions::BustHomepageCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article, featured: true) }
    let(:worker) { subject }
    let(:buster) { instance_double(EdgeCache::Buster) }

    before do
      allow(EdgeCache::Buster).to receive(:new).and_return(buster)
      allow(buster).to receive(:bust)
    end

    it "busts the homepage cache when reactable is an Article" do
      reaction = create(:reaction, reactable: article, user: user)

      worker.perform(reaction.id)

      expect(buster).to have_received(:bust).with("/").exactly(2).times
      expect(buster).to have_received(:bust).with("/?i=i")
      expect(buster).to have_received(:bust).with("?i=i")
    end

    it "doesn't bust the homepage cache when reactable is a Comment" do
      comment = create(:comment, commentable: article)
      comment_reaction = create(:reaction, reactable: comment, user: user)

      worker.perform(comment_reaction.id)

      expect(buster).not_to have_received(:bust).with("/")
      expect(buster).not_to have_received(:bust).with("/?i=i")
      expect(buster).not_to have_received(:bust).with("?i=i")
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end
  end
end
