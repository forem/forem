require "rails_helper"

RSpec.describe Reaction do
  let(:user) { create(:user) }
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author, published: true, tags: "") }

  def create_article_reactions(count, created_at: 2.months.ago)
    Array.new(count) do
      prior_article = create(:article, user: author, published: true, tags: "")
      create(:reaction, user: user, reactable: prior_article, category: "like", created_at: created_at)
    end
  end

  describe "check_for_reaction_ring callback" do
    before do
      stub_const("Spam::ReactionRingDetector::MIN_REACTIONS_THRESHOLD", 5)
      allow(Spam::ReactionRingDetectionWorker).to receive(:perform_async)
    end

    context "when reaction is not public" do
      let(:user) { create(:user, :trusted) } # Trusted users can create privileged reactions

      it "does not trigger ring detection" do
        # Create a privileged reaction (not public)
        create(:reaction, user: user, reactable: article, category: "thumbsdown")

        expect(Spam::ReactionRingDetectionWorker).not_to have_received(:perform_async)
      end
    end

    context "when reaction is not on an article" do
      let(:comment) { create(:comment) }

      it "does not trigger ring detection" do
        create(:reaction, user: user, reactable: comment, category: "like")

        expect(Spam::ReactionRingDetectionWorker).not_to have_received(:perform_async)
      end
    end

    context "when user has insufficient reactions" do
      it "does not trigger ring detection" do
        create(:reaction, user: user, reactable: article, category: "like")

        expect(Spam::ReactionRingDetectionWorker).not_to have_received(:perform_async)
      end
    end

    context "when user has sufficient reactions and creates a public reaction on article" do
      before do
        # Create enough reactions to meet the threshold over 3 months
        create_article_reactions(4)
      end

      it "triggers ring detection for public reaction categories", :aggregate_failures do
        create(:reaction, user: user, reactable: article, category: "like")
        create(:reaction, user: user, reactable: article, category: "unicorn")

        expect(Spam::ReactionRingDetectionWorker).to have_received(:perform_async).with(user.id).twice
      end
    end

    context "when user has old reactions outside 3-month window" do
      before do
        # Create reactions older than 3 months
        create_article_reactions(6, created_at: 4.months.ago)
      end

      it "does not trigger ring detection" do
        create(:reaction, user: user, reactable: article, category: "like")

        expect(Spam::ReactionRingDetectionWorker).not_to have_received(:perform_async)
      end
    end
  end
end
