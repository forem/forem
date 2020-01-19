require "rails_helper"

RSpec.describe Reactions::BustHomepageCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article, featured: true) }
    let(:reaction) { create(:reaction, reactable: article, user: user) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment, user: user) }
    let(:worker) { subject }
    let(:buster) { double }

    before do
      allow(buster).to receive(:bust)
    end

    it "busts the homepage cache when reactable is an Article" do
      worker.perform(reaction.id, buster)
      expect(buster).to have_received(:bust).exactly(4)
    end

    it "doesn't bust the homepage cache when reactable is a Comment" do
      worker.perform(comment_reaction.id, buster)
      expect(buster).not_to have_received(:bust)
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1, buster)
      end.not_to raise_error
    end
  end
end
