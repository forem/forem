require "rails_helper"

RSpec.describe Concepts::BackfillClassifierWorker, type: :worker do
  let(:embedding1) { Array.new(768, 0.1) }
  let(:embedding2) { Array.new(768) { |i| i.even? ? 0.1 : -0.1 } } # orthogonal to embedding1
  let!(:concept) { create(:concept, anchor_embedding: embedding1) }

  # We use update_column here to bypass any potential validation issues during setup
  let!(:article_matching) do
    art = create(:article, published: true)
    art.update_column(:semantic_embedding, embedding1)
    art
  end

  let!(:article_far) do
    art = create(:article, published: true)
    art.update_column(:semantic_embedding, embedding2)
    art
  end

  let!(:comment_matching) do
    com = create(:comment)
    com.update_column(:semantic_embedding, embedding1)
    com
  end

  let!(:comment_far) do
    com = create(:comment)
    com.update_column(:semantic_embedding, embedding2)
    com
  end

  it "retroactively creates memberships for matching published articles and comments" do
    expect {
      described_class.new.perform(concept.id)
    }.to change(ConceptMembership, :count).by(2)

    expect(concept.articles).to contain_exactly(article_matching)
    expect(concept.comments).to contain_exactly(comment_matching)
  end

  it "cleans up existing memberships before running backfill" do
    create(:concept_membership, concept: concept, record: article_matching, distance: 0.1)
    create(:concept_membership, concept: concept, record: article_far, distance: 0.9) # stale membership
    create(:concept_membership, concept: concept, record: comment_matching, distance: 0.1)

    expect {
      described_class.new.perform(concept.id)
    }.to change(ConceptMembership, :count).by(-1) # Deletes 3, inserts 2 => net change -1

    expect(concept.articles).to contain_exactly(article_matching)
    expect(concept.comments).to contain_exactly(comment_matching)
  end
end
