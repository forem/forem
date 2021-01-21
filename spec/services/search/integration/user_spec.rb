require "rails_helper"

RSpec.describe "Compare ES search to PG search for User", type: :feature do
  let(:es_described_class) { Search::User }
  let(:pg_described_class) { Search::Postgres::User }

  describe "::search_documents", elasticsearch: "User" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    def es_reindex
      user1.index_to_elasticsearch_inline
      user2.index_to_elasticsearch_inline
      es_described_class.refresh_index
    end

    it "works with profile fields" do
      user2.available_for = "acme"
      user2.save!

      es_reindex

      es_results = es_described_class.search_documents(params: { search_fields: "acme" })
      pg_results = pg_described_class.search_documents(term: "acme")

      expect(pg_results.length).to be(1)
      expect(es_results).to eq(pg_results)
    end

    it "works with username" do
      user2.username = "acme"
      user2.save!

      es_reindex

      es_results = es_described_class.search_documents(params: { search_fields: "acme" })
      pg_results = pg_described_class.search_documents(term: "acme")

      expect(pg_results.length).to be(1)
      expect(es_results).to eq(pg_results)
    end
  end
end
