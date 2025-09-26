# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reaction ring detection", type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, published: true) }

  describe "check_for_reaction_ring callback" do
    context "when reaction is not public" do
      let(:user) { create(:user, :trusted) }  # Trusted users can create privileged reactions
      
      it "does not trigger ring detection" do
        expect(Spam::ReactionRingDetectionWorker).not_to receive(:perform_async)
        
        # Create a privileged reaction (not public)
        create(:reaction, user: user, reactable: article, category: "thumbsdown")
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
        # Create enough reactions to meet the threshold over 3 months
        create_list(:reaction, 50, user: user, reactable_type: "Article", category: "like", created_at: 2.months.ago)
      end

      it "triggers ring detection" do
        expect(Spam::ReactionRingDetectionWorker).to receive(:perform_async).with(user.id)
        
        create(:reaction, user: user, reactable: article, category: "like")
      end
    end

    context "when user creates a public reaction" do
      before do
        create_list(:reaction, 50, user: user, reactable_type: "Article", category: "like", created_at: 2.months.ago)
      end

      it "triggers ring detection" do
        expect(Spam::ReactionRingDetectionWorker).to receive(:perform_async).with(user.id)
        
        create(:reaction, user: user, reactable: article, category: "unicorn")
      end
    end

    context "when user has old reactions outside 3-month window" do
      before do
        # Create reactions older than 3 months
        create_list(:reaction, 60, user: user, reactable_type: "Article", category: "like", created_at: 4.months.ago)
      end

      it "does not trigger ring detection" do
        expect(Spam::ReactionRingDetectionWorker).not_to receive(:perform_async)
        
        create(:reaction, user: user, reactable: article, category: "like")
      end
    end
  end
end
