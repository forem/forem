require "rails_helper"

RSpec.describe Homepage::ArticlesQuery, type: :query do
  describe ".call" do
    it "returns a relation object" do
      expect(described_class.call).to be_a(ActiveRecord::Relation)
    end

    it "does not return draft articles" do
      article = create(:article, published: false, published_at: nil)

      expect(described_class.call.ids).not_to include(article.id)
    end

    it "returns both approved and unapproved articles by default" do
      approved_article = create(:article, approved: true)
      unapproved_article = create(:article, approved: false)

      expected_result = [approved_article.id, unapproved_article.id]
      expect(described_class.call.ids).to match_array(expected_result)
    end

    it "returns approved articles", :aggregate_failures do
      approved_article = create(:article, approved: true)
      unapproved_article = create(:article, approved: false)

      result = described_class.call(approved: true).ids
      expect(result).to include(approved_article.id)
      expect(result).not_to include(unapproved_article.id)
    end

    it "returns unapproved articles" do
      approved_article = create(:article, approved: true)
      unapproved_article = create(:article, approved: false)

      result = described_class.call(approved: false).ids
      expect(result).not_to include(approved_article.id)
      expect(result).to include(unapproved_article.id)
    end

    it "returns only published articles" do
      article = create(:article)

      expect(described_class.call.ids).to eq([article.id])
    end

    it "paginates by default" do
      stub_const("Homepage::ArticlesQuery::DEFAULT_PER_PAGE", 1)

      create_list(:article, 2)

      expect(described_class.call.size).to eq(1)
    end

    it "supports pagination params" do
      create_list(:article, 2)

      expect(described_class.call(page: 1, per_page: 1).size).to eq(1)
    end

    it "filters by publication date", :aggregate_failures do
      article = create(:article)

      expect(described_class.call(published_at: article.published_at).size).to eq(1)
      expect(described_class.call(published_at: 1.month.ago..).size).to eq(1)
      expect(described_class.call(published_at: 1.month.from_now)).to be_empty
    end

    it "sorts by the hotness_score", :aggregate_failures do
      article1, article2 = create_list(:article, 2)

      article1.update_columns(hotness_score: 1)
      article2.update_columns(hotness_score: 2)

      result = described_class.call(sort_by: :hotness_score, sort_direction: :desc).ids
      expect(result).to eq([article2.id, article1.id])

      result = described_class.call(sort_by: :hotness_score, sort_direction: :asc).ids
      expect(result).to eq([article1.id, article2.id])
    end

    it "sorts by the public_reactions_count" do
      article1, article2 = create_list(:article, 2)

      article1.update_columns(public_reactions_count: 1)
      article2.update_columns(public_reactions_count: 2)

      result = described_class.call(sort_by: :public_reactions_count, sort_direction: :desc).ids
      expect(result).to eq([article2.id, article1.id])

      result = described_class.call(sort_by: :public_reactions_count, sort_direction: :asc).ids
      expect(result).to eq([article1.id, article2.id])
    end

    it "does not sort by unknown parameters" do
      article1, article2 = create_list(:article, 2)

      article1.update_columns(comments_count: 1)
      article2.update_columns(comments_count: 2)

      result = described_class.call(sort_by: :comments_count, sort_direction: :desc).ids
      expect(result).not_to eq([article2.id, article1.id])
    end
  end
end
