require "rails_helper"

RSpec.describe "Compare ES search to PG search for UserUsername", type: :feature do
  let(:es_described_class) { Search::User }
  let(:pg_described_class) { Search::Postgres::UserUsername }

  describe "::search_documents" do
    let(:user1) { create(:user, username: "star_wars_is_the_best") }
    let(:user2) { create(:user, username: "star_trek_is_the_best") }

    before do
      user1.index_to_elasticsearch_inline
      user2.index_to_elasticsearch_inline
      es_described_class.refresh_index
    end

    it "searches with username" do
      es_results = es_described_class.search_usernames(user1.username)
      pg_results = pg_described_class.search_documents(user1.username)

      expect(pg_results.length).to be(1)
      expect(pg_results).to match([user1.username])

      expect(es_results).to eq(pg_results)
    end

    it "analyzes wildcards" do
      user3 = create(:user, username: "does_not_start_with_a_star")
      user3.index_to_elasticsearch_inline
      es_described_class.refresh_index

      es_results = es_described_class.search_usernames("star*")
      pg_results = pg_described_class.search_documents("star*")

      expect(pg_results).to match([user1.username, user2.username])
      expect(pg_results).not_to include(user3.username)

      expect(es_results).to eq(pg_results)
    end
  end
end
