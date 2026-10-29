require "rails_helper"

RSpec.describe Concept, type: :model do
  let(:embedding) { Array.new(768, 0.1) }

  describe "slug generation" do
    it "generates a parameterized slug from the name on create" do
      concept = create(:concept, name: "Claude Code CLI", anchor_embedding: embedding)
      expect(concept.slug).to eq("claude-code-cli")
    end

    it "adds a counter suffix if the slug is already taken" do
      create(:concept, name: "Claude Code", anchor_embedding: embedding)
      concept2 = create(:concept, name: "Claude Code", anchor_embedding: embedding)
      expect(concept2.slug).to eq("claude-code-1")
    end

    it "updates the slug when the name changes on update" do
      concept = create(:concept, name: "Claude Code", anchor_embedding: embedding)
      expect(concept.slug).to eq("claude-code")

      concept.update!(name: "Claude Code Agent")
      expect(concept.slug).to eq("claude-code-agent")
    end
  end

  describe "validations" do
    it "requires anchor_embedding" do
      concept = build(:concept, anchor_embedding: nil)
      expect(concept).not_to be_valid
    end

    it "allows similarity_threshold to be nil" do
      concept = build(:concept, similarity_threshold: nil)
      expect(concept).to be_valid
    end

    it "requires similarity_threshold to be between 0.0 and 1.0" do
      concept_valid = build(:concept, similarity_threshold: 0.5)
      concept_low = build(:concept, similarity_threshold: -0.1)
      concept_high = build(:concept, similarity_threshold: 1.1)

      expect(concept_valid).to be_valid
      expect(concept_low).not_to be_valid
      expect(concept_high).not_to be_valid
    end
  end
end
