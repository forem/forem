require "rails_helper"

RSpec.describe ContextNote, type: :model do
  let(:article) { create(:article) }
  let(:tag) { create(:tag) }
  let(:trend) { create(:trend) }

  describe "associations" do
    it "belongs to an article" do
      context_note = create(:context_note, article: article)
      expect(context_note.article).to eq(article)
    end

    it "belongs to a tag (optional)" do
      context_note = create(:context_note, article: article, tag: tag)
      expect(context_note.tag).to eq(tag)
    end

    it "belongs to a trend (optional)" do
      context_note = create(:context_note, article: article, trend: trend)
      expect(context_note.trend).to eq(trend)
    end
  end

  describe "validations" do
    it "validates uniqueness of article scoped to tag" do
      create(:context_note, article: article, tag: tag)
      duplicate = build(:context_note, article: article, tag: tag)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:article]).to be_present
    end

    it "validates uniqueness of article scoped to trend" do
      create(:context_note, article: article, trend: trend)
      duplicate = build(:context_note, article: article, trend: trend)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:article]).to be_present
    end

    it "allows same article with different tags" do
      tag2 = create(:tag)
      create(:context_note, article: article, tag: tag)
      context_note2 = build(:context_note, article: article, tag: tag2)
      expect(context_note2).to be_valid
    end

    it "allows same article with different trends" do
      trend2 = create(:trend)
      create(:context_note, article: article, trend: trend)
      context_note2 = build(:context_note, article: article, trend: trend2)
      expect(context_note2).to be_valid
    end
  end
end
