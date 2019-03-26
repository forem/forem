require "rails_helper"

RSpec.describe Reactions::BustHomepageCacheJob, type: :job do
  include_examples "#enqueues_job", "bust_homepage_cache_from_reactions", 2

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:article) { create(:article, featured: true) }
    let(:reaction) { create(:reaction, reactable: article, user: user) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment, user: user) }
    let(:buster) { double }

    before do
      allow(buster).to receive(:bust)
    end

    it "busts the homepage cache when reactable is an Article" do
      described_class.perform_now(reaction.id, buster)
      expect(buster).to have_received(:bust).exactly(4)
    end

    it "doesn't bust the homepage cache when reactable is a Comment" do
      described_class.perform_now(comment_reaction.id, buster)
      expect(buster).not_to have_received(:bust)
    end

    it "doesn't fail if a reaction doesn't exist" do
      described_class.perform_now(Reaction.maximum(:id).to_i + 1)
    end
  end
end
