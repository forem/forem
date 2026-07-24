require "rails_helper"

RSpec.describe ConceptMembership, type: :model do
  describe "validations" do
    it "is valid with concept, record, and distance" do
      membership = build(:concept_membership)
      expect(membership).to be_valid
    end

    it "requires distance" do
      membership = build(:concept_membership, distance: nil)
      expect(membership).not_to be_valid
    end

    it "enforces uniqueness of record scoped to concept" do
      concept = create(:concept)
      article = create(:article)
      create(:concept_membership, concept: concept, record: article)

      duplicate = build(:concept_membership, concept: concept, record: article)
      expect(duplicate).not_to be_valid
    end

    it "allows same record ID with different record type" do
      concept = create(:concept)
      article = create(:article)
      comment = build(:comment, id: article.id)

      create(:concept_membership, concept: concept, record: article)
      duplicate = build(:concept_membership, concept: concept, record: comment)
      expect(duplicate).to be_valid
    end
  end
end
