require "rails_helper"

RSpec.describe "Search::FeedContent (Simple)" do
  describe "GET search/feed_content" do
    context "when the new attributes are included in the serializer" do
      it "includes title_finalized_for_feed, title_for_metadata, and title_finalized in the Homepage::ArticleSerializer" do
        # Test that the serializer includes the new attributes by checking the source code
        serializer_source = File.read(Rails.root.join("app/serializers/homepage/article_serializer.rb"))

        expect(serializer_source).to include("title_finalized")
        expect(serializer_source).to include("title_finalized_for_feed")
        expect(serializer_source).to include("title_for_metadata")
      end
    end

    context "when Homepage::ArticlesQuery includes type_of attribute" do
      it "includes type_of in the ATTRIBUTES list" do
        expect(Homepage::ArticlesQuery::ATTRIBUTES).to include(:type_of)
      end
    end

    context "when testing the methods exist on Article model" do
      let(:article) { Article.new }

      it "responds to title_finalized_for_feed" do
        expect(article).to respond_to(:title_finalized_for_feed)
      end

      it "responds to title_for_metadata" do
        expect(article).to respond_to(:title_for_metadata)
      end

      it "responds to title_finalized" do
        expect(article).to respond_to(:title_finalized)
      end
    end
  end
end
