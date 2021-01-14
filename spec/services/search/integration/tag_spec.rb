require "rails_helper"

RSpec.describe "Compare ES search to PG search for Tag", type: :feature do
  let(:es_described_class) { Search::Tag }
  let(:pg_described_class) { Search::Postgres::Tag }

  # we remove `last_indexed_at` from ES results as PostgreSQL results are simply
  # rows in the table. We could use `updated_at` in lieu, but it's probably not worth it
  def clean_es_results(results)
    results.map do |result|
      result.except("last_indexed_at")
    end
  end

  describe "::search_documents", elasticsearch: "Tag" do
    it "works with a simple query" do
      tag1 = create(:tag, :search_indexed, name: "tag1")

      es_described_class.refresh_index

      es_results = es_described_class.search_documents(tag1.name)
      pg_results = pg_described_class.search_documents(tag1.name)

      expect(clean_es_results(es_results)).to eq(pg_results)
    end

    it "works with trailing wildcards" do
      create(:tag, :search_indexed, name: "tag1")
      create(:tag, :search_indexed, name: "tag2")
      tag3 = create(:tag, :search_indexed, name: "3tag")

      es_described_class.refresh_index

      es_results = es_described_class.search_documents("tag*")
      pg_results = pg_described_class.search_documents("tag*")

      expect(clean_es_results(es_results)).to eq(pg_results)
      expect(pg_results).not_to match(a_hash_including("name" => tag3.name))
    end

    it "rejects leading wildcards" do
      create(:tag, :search_indexed, name: "tag1")
      es_described_class.refresh_index

      expect { es_described_class.search_documents("name:*tag") }.to raise_error(Search::Errors::Transport::BadRequest)
      expect(pg_described_class.search_documents("*tag")).to be_empty
    end
  end
end
