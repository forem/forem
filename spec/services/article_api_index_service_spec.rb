require "rails_helper"

RSpec.describe ArticleApiIndexService, type: :service do
  describe "#get" do
    let!(:article) { create(:article, published: true) }

    context "when given tags has passed in" do
      let(:params) { { tags: "javascript, css" } }

      it "returns proper scope" do
        expect(described_class.new(params).get).to match_array(article)
      end
    end

    context "when given tags_exclude has passed in" do
      let(:params) { { tags_exclude: "node, java" } }

      it "returns proper scope" do
        expect(described_class.new(params).get).to match_array(article)
      end
    end

    context "when tags and tags_excluded have passed in" do
      let(:params) do
        {
          tags: "javascript, css",
          tags_exclude: "node, java"
        }
      end

      it "returns proper scope" do
        expect(described_class.new(params).get).to match_array(article)
      end
    end
  end
end
