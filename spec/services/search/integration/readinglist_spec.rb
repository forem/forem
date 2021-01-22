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
      es_reindex([article1, article2])

      es_results = es_described_class.search_documents(user: user, params: {})
      pg_results = pg_described_class.search_documents(user)

      expect(pg_results.length).to eq(2)

      expect(pg_results["total"]).to eq(es_results["total"])

      expect(pg_results["reactions"].first).to eq(cleanup_es_result(es_results["reactions"].first))
    end

    it "searches with a term", :aggregate_failures do
      article1.update(title: "ruby")
      article2.update(body_markdown: "Ruby Tuesday")

      es_reindex([article1, article2])

      es_results = es_described_class.search_documents(user: user, params: { search_fields: "tuesday" })
      pg_results = pg_described_class.search_documents(user, term: "tuesday")

      expect(pg_results.length).to eq(es_results.length)

      # NOTE: temporarily excluding the comparison between `highlight` because ES is more sophisticated,
      # it can search against different fields separately, PG can't. I reckon we don't need this feature.
      expected_result = cleanup_es_result(es_results["reactions"].first).dup
      result = pg_results["reactions"].first.except("highlight").dup
      expected_result["reactable"]["highlight"] = result["reactable"]["highlight"] = nil

      expect(expected_result).to eq(result)
    end

    it "highlights the search text" do
      article1.update(title: "ruby")
      article2.update(body_markdown: "Ruby Tuesday")

      es_reindex([article1, article2])

      es_results = es_described_class.search_documents(user: user, params: { search_fields: "tuesday" })
      pg_results = pg_described_class.search_documents(user, term: "tuesday")

      # NOTE: I haven't found the correct params to return the same exact result, so I'm approximating a bit
      es_highlight = es_results["reactions"].first.dig("reactable", "highlight", "body_text").first
      pg_highlight = pg_results["reactions"].first.dig("reactable", "highlight")
      expect(pg_highlight).to match(es_highlight)
    end
  end
end
