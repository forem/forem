# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reaction ring detection", type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, published: true) }

  describe "check_for_reaction_ring callback" do
    context "when reaction is not public" do
      it "does not trigger ring detection" do
        expect(Spam::ReactionRingDetectionWorker).not_to receive(:perform_async)
        
        create(:reaction, user: user, reactable: article, category: "vomit")
      end
    end

    context "when reaction is not on an article" do
      let(:comment) { create(:comment) }

      it "does not trigger ring detection" do
        expect(Spam::ReactionRingDetectionWorker).not_to receive(:perform_async)
        
        create(:reaction, user: user, reactable: comment, category: "like")
      end
    end

    context "when user has insufficient reactions" do
      it "does not trigger ring detection" do
        expect(Spam::ReactionRingDetectionWorker).not_to receive(:perform_async)
        
        create(:reaction, user: user, reactable: article, category: "like")
      end
    end

    context "when user has sufficient reactions and creates a public reaction on article" do
      before do
        # Create enough reactions to meet the threshold
        create_list(:reaction, 50, user: user, reactable_type: "Article", category: "like")
      end

      it "triggers ring detection" do
        expect(Spam::ReactionRingDetectionWorker).to receive(:perform_async).with(user.id)
        
        create(:reaction, user: user, reactable: article, category: "like")
      end
    end

    context "when user creates a readinglist reaction" do
      before do
        create_list(:reaction, 50, user: user, reactable_type: "Article", category: "like")
      end

      it "triggers ring detection" do
        expect(Spam::ReactionRingDetectionWorker).to receive(:perform_async).with(user.id)
        
        create(:reaction, user: user, reactable: article, category: "readinglist")
      end
    end
  end
end
