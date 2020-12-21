require "rails_helper"

RSpec.describe "Search::Indicies", type: :service do
  before { create_list(:article, 10) }

  describe ".clear!" do
    it "removes all search documents for the given class" do
      expect do
        Search::Indices.clear!(Article)
      end.to change(PgSearch::Document, :count).by(-10)
    end
  end

  describe ".rebuild!" do
    it "rebuilds the search index for the given class", :aggregate_failures do
      allow(PgSearch::Document).to receive(:where).and_return(Article.all)
      expect do
        Search::Indices.rebuild!(Article)
      end.not_to change(PgSearch::Document, :count)
      expect(PgSearch::Document).to have_received(:where).with(searchable_type: "Article")
    end
  end
end
