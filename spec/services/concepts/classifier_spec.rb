require "rails_helper"

RSpec.describe Concepts::Classifier do
  let(:embedding1) { Array.new(768, 0.1) }
  let(:embedding2) { Array.new(768, 0.11) }
  let(:embedding3) { Array.new(768) { |i| i.even? ? 0.1 : -0.1 } } # orthogonal/far away

  let!(:concept1) { create(:concept, anchor_embedding: embedding1) }
  let!(:concept2) { create(:concept, anchor_embedding: embedding2) }

  describe "#call" do
    context "with an article" do
      it "creates concept memberships for matching concepts" do
        article = create(:article, semantic_embedding: embedding1)
        classifier = described_class.new(article)

        expect {
          classifier.call(threshold: 0.14)
        }.to change(ConceptMembership, :count).by(2)

        expect(article.concepts).to contain_exactly(concept1, concept2)
      end

      it "removes concept memberships that no longer qualify" do
        article = create(:article, semantic_embedding: embedding1)
        create(:concept_membership, concept: concept1, record: article, distance: 0.0)
        create(:concept_membership, concept: concept2, record: article, distance: 0.05)

        # Update embedding to be far away
        article.update_column(:semantic_embedding, embedding3)
        article.reload
        classifier = described_class.new(article)

        expect {
          classifier.call(threshold: 0.14)
        }.to change(ConceptMembership, :count).by(-2)

        expect(article.concepts).to be_empty
      end
    end

    context "with a comment" do
      it "creates concept memberships for matching concepts" do
        comment = create(:comment, semantic_embedding: embedding1)
        classifier = described_class.new(comment)

        expect {
          classifier.call(threshold: 0.14)
        }.to change(ConceptMembership, :count).by(2)

        expect(comment.concepts).to contain_exactly(concept1, concept2)
      end

      it "removes concept memberships that no longer qualify" do
        comment = create(:comment, semantic_embedding: embedding1)
        create(:concept_membership, concept: concept1, record: comment, distance: 0.0)
        create(:concept_membership, concept: concept2, record: comment, distance: 0.05)

        # Update embedding to be far away
        comment.update_column(:semantic_embedding, embedding3)
        comment.reload
        classifier = described_class.new(comment)

        expect {
          classifier.call(threshold: 0.14)
        }.to change(ConceptMembership, :count).by(-2)

        expect(comment.concepts).to be_empty
      end
    end
  end
end
