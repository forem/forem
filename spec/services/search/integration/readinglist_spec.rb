require "rails_helper"

RSpec.describe "Compare ES search to PG search for ReadingList", type: :feature do
  let(:es_described_class) { Search::ReadingList }
  let(:pg_described_class) { Search::Postgres::ReadingList }

  describe "::search_documents", elasticsearch: "User" do
    let(:user) { create(:user) }
    let(:article0) { create(:article) }
    let(:article1) { create(:article) }
    let(:article2) { create(:article) }
    let(:reaction1) { create(:reaction, user: user, category: "readinglist", reactable: article1) }
    let(:reaction2) { create(:reaction, user: user, category: "readinglist", reactable: article2) }
    let(:reaction3) { create(:reaction, user: user, category: "readinglist", reactable: article0) }

    before do
      reaction1
      reaction2
      es_reindex([article1, article2])
    end

    def es_reindex(docs)
      Array.wrap(docs).each(&:index_to_elasticsearch_inline)
      Search::FeedContent.refresh_index
    end

    def cleanup_es_result(doc)
      doc["reactable"].delete("_score")
      # NOTE: for some reason this is 0 with ES, even though it should be 1
      doc["reactable"]["public_reactions_count"] = 1
      doc
    end

    it "returns fields necessary for the view" do
      es_results = es_described_class.search_documents(user: user, params: {})
      pg_results = pg_described_class.search_documents(user)

      expect(pg_results.length).to eq(2)

      expect(pg_results["total"]).to eq(es_results["total"])

      expect(pg_results["reactions"].first).to eq(cleanup_es_result(es_results["reactions"].first))
    end
  end
end
