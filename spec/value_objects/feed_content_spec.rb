require "rails_helper"

RSpec.describe SearchResources::FeedContent do
  subject(:requested_resource) do
    described_class.new(feed_params: feed_params)
  end

  describe "#article_search?" do
    context "when the class is Article, search fields are blank and sort_by is present" do
      let(:feed_params) do
        {
          class_name: "Article",
          search_fields: "",
          sort_by: double
        }
      end

      it "returns true" do
        expect(requested_resource.article_search?).to be true
      end
    end

    context "when the class is not Article, search fields are blank and sort_by is present" do
      let(:feed_params) do
        {
          class_name: "Comment",
          search_fields: "",
          sort_by: double
        }
      end

      it "return false" do
        expect(requested_resource.article_search?).to be false
      end
    end

    context "when the class Article, search fields are not blank and sort_by is present" do
      let(:feed_params) do
        {
          class_name: "Article",
          search_fields: "keyword",
          sort_by: double
        }
      end

      it "return false" do
        expect(requested_resource.article_search?).to be false
      end
    end

    context "when the class Article, search fields are blank and sort_by is not present" do
      let(:feed_params) do
        {
          class_name: "Article",
          search_fields: "",
          sort_by: nil
        }
      end

      it "return false" do
        expect(requested_resource.article_search?).to be false
      end
    end
  end
end
