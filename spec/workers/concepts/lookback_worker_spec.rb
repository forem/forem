require "rails_helper"

RSpec.describe Concepts::LookbackWorker, type: :worker do
  let(:embedding1) { Array.new(768, 0.1) }
  let(:embedding2) { Array.new(768) { |i| i.even? ? 0.1 : -0.1 } } # orthogonal to embedding1
  let!(:concept) { create(:concept, anchor_embedding: embedding1, max_lookback_days: 0) }

  # Test Helper to create a matching article at a specific time
  def create_matching_article(published_at)
    art = create(:article, published: true)
    art.update_columns(semantic_embedding: embedding1, published_at: published_at)
    art
  end

  # Test Helper to create a matching comment at a specific time
  def create_matching_comment(created_at)
    com = create(:comment)
    com.update_columns(semantic_embedding: embedding1, created_at: created_at)
    com
  end

  describe "#perform" do
    context "when running lookback for the first time (max_lookback_days = 0)" do
      let!(:art_within_range) { create_matching_article(10.days.ago) }
      let!(:art_out_of_range) { create_matching_article(50.days.ago) }
      let!(:com_within_range) { create_matching_comment(20.days.ago) }
      let!(:com_out_of_range) { create_matching_comment(60.days.ago) }

      it "only creates memberships for records within the specified days window" do
        expect {
          described_class.new.perform(concept.id, 40)
        }.to change(ConceptMembership, :count).by(2)

        expect(concept.articles).to contain_exactly(art_within_range)
        expect(concept.comments).to contain_exactly(com_within_range)
        expect(concept.reload.max_lookback_days).to eq(40)
      end

      it "excludes records with embedding distance greater than 0.14" do
        art_far = create(:article, published: true)
        art_far.update_columns(semantic_embedding: embedding2, published_at: 10.days.ago)
        
        com_far = create(:comment)
        com_far.update_columns(semantic_embedding: embedding2, created_at: 10.days.ago)

        expect {
          described_class.new.perform(concept.id, 40)
        }.to change(ConceptMembership, :count).by(2)

        expect(concept.articles).not_to include(art_far)
        expect(concept.comments).not_to include(com_far)
      end
    end

    context "when running subsequent lookbacks (e.g. from 40 to 70 days)" do
      before do
        concept.update!(max_lookback_days: 40)
      end

      # Already covered period (10 days ago) - should not be processed again
      let!(:art_already_covered) { create_matching_article(10.days.ago) }
      
      # Overlap period (39 days ago, overlaps with 38-40 window) - should be processed again but handle duplicates gracefully
      let!(:art_overlap) { create_matching_article(39.days.ago) }
      
      # Delta period (50 days ago, between 40 and 70) - should be processed
      let!(:art_delta) { create_matching_article(50.days.ago) }
      let!(:com_delta) { create_matching_comment(60.days.ago) }

      # Out of range (80 days ago) - should not be processed
      let!(:art_out_of_range) { create_matching_article(80.days.ago) }

      it "only queries records within the delta window (plus 2 days overlap) and handles duplicate memberships gracefully" do
        # Seed an existing membership for the overlap record to simulate duplicate detection
        create(:concept_membership, concept: concept, record: art_overlap, distance: 0.05)

        expect {
          described_class.new.perform(concept.id, 70)
        }.to change(ConceptMembership, :count).by(2) # art_delta, com_delta are added. art_overlap is upserted/updated.

        expect(concept.articles).to include(art_delta, art_overlap)
        expect(concept.articles).not_to include(art_already_covered, art_out_of_range)
        expect(concept.comments).to contain_exactly(com_delta)
        expect(concept.reload.max_lookback_days).to eq(70)
      end
    end

    context "when requested days is less than or equal to existing max_lookback_days" do
      before do
        concept.update!(max_lookback_days: 40)
      end

      it "returns early and does not query or create memberships" do
        expect(Article).not_to receive(:published)
        expect(Comment).not_to receive(:select)

        expect {
          described_class.new.perform(concept.id, 30)
        }.not_to change(ConceptMembership, :count)

        expect(concept.reload.max_lookback_days).to eq(40)
      end
    end

    context "with invalid arguments" do
      it "returns early when the concept does not exist" do
        expect(Article).not_to receive(:published)
        expect {
          described_class.new.perform(-1, 40)
        }.not_to change(ConceptMembership, :count)
      end

      it "returns early when days is less than or equal to 0" do
        expect(Article).not_to receive(:published)
        expect {
          described_class.new.perform(concept.id, 0)
        }.not_to change(ConceptMembership, :count)

        expect {
          described_class.new.perform(concept.id, -5)
        }.not_to change(ConceptMembership, :count)
      end
    end
  end
end
