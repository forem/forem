require "rails_helper"

RSpec.describe Articles::Feeds::Tag, type: :service do
  let(:tag) { create(:tag, name: "ruby") }
  let!(:article1) { create(:article, published: true, tags: [tag.name]) }
  let!(:article2) { create(:article, published: true, tags: [tag.name]) }

  describe ".call with optimizations" do
    context "when passing a Tag object" do
      it "uses the tag object efficiently without additional lookups" do
        # Mock to ensure we don't do additional Tag.find_by calls
        expect(Tag).not_to receive(:find_by)
        
        result = described_class.call(tag, number_of_articles: 10, page: 1)
        
        expect(result).to include(article1, article2)
      end
    end

    context "when passing a tag name string" do
      it "uses cached_tagged_with_any when feature flag is enabled" do
        allow(FeatureFlag).to receive(:enabled?).with(:optimize_article_tag_query).and_return(true)
        
        expect(Article).to receive(:cached_tagged_with_any).with(tag.name).and_call_original
        
        result = described_class.call(tag.name, number_of_articles: 10, page: 1)
        
        expect(result).to include(article1, article2)
      end

      it "falls back to tag.articles when feature flag is disabled" do
        allow(FeatureFlag).to receive(:enabled?).with(:optimize_article_tag_query).and_return(false)
        
        result = described_class.call(tag.name, number_of_articles: 10, page: 1)
        
        expect(result).to include(article1, article2)
      end
    end

    context "when tag doesn't exist" do
      it "returns empty relation gracefully" do
        allow(FeatureFlag).to receive(:enabled?).with(:optimize_article_tag_query).and_return(false)
        
        result = described_class.call("nonexistent", number_of_articles: 10, page: 1)
        
        expect(result).to be_empty
      end
    end

    it "includes all necessary associations to prevent N+1 queries" do
      result = described_class.call(tag, number_of_articles: 10, page: 1)
      
      # Verify that associations are properly loaded
      expect(result.includes_values).to include(
        { top_comments: :user },
        :distinct_reaction_categories,
        :context_notes,
        :subforem
      )
      expect(result.preload_values).to include(:user, :organization)
    end
  end
end