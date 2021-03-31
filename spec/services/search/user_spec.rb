require "rails_helper"

RSpec.describe Search::User, type: :service do
  it "defines INDEX_NAME, INDEX_ALIAS, and MAPPINGS", :aggregate_failures do
    expect(described_class::INDEX_NAME).not_to be_nil
    expect(described_class::INDEX_ALIAS).not_to be_nil
    expect(described_class::MAPPINGS).not_to be_nil
  end

  describe "::search_documents", elasticsearch: "User" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "parses user document hits from search response" do
      mock_search_response = { "hits" => { "hits" => {} } }
      allow(described_class).to receive(:search) { mock_search_response }
      described_class.search_documents(params: {})
      expect(described_class).to have_received(:search).with(body: a_kind_of(Hash))
    end

    context "with a query" do
      it "searches by search_fields" do
        allow(user1).to receive(:available_for).and_return("ruby")
        allow(user2).to receive(:employer_name).and_return("Ruby Tuesday")
        index_documents([user1, user2])
        query_params = { size: 5, search_fields: "ruby" }

        user_docs = described_class.search_documents(params: query_params)
        expect(user_docs.count).to eq(2)
        doc_ids = user_docs.map { |t| t["id"] }
        expect(doc_ids).to include(user1.id, user2.id)
      end

      it "searches by a username" do
        allow(user1).to receive(:username).and_return("kyloren")
        index_documents([user1])
        query_params = { size: 5, search_fields: "kyloren" }

        user_docs = described_class.search_documents(params: query_params)
        expect(user_docs.count).to eq(1)
        doc_ids = user_docs.map { |t| t["id"] }
        expect(doc_ids).to include(user1.id)
      end
    end

    context "with a filter" do
      it "searches by excluding roles" do
        user1.add_role(:admin)
        user2.add_role(:suspended)
        index_documents([user1, user2])
        query_params = { size: 5, exclude_roles: %w[suspended banned] }

        user_docs = described_class.search_documents(params: query_params)
        expect(user_docs.count).to eq(1)
        doc_ids = user_docs.map { |t| t["id"] }
        expect(doc_ids).to match_array([user1.id])
      end
    end
  end

  describe "::search_usernames", elasticsearch: "User" do
    let(:user1) { create(:user, username: "star_wars_is_the_best") }
    let(:user2) { create(:user, username: "star_trek_is_the_best") }

    before do
      index_documents([user1, user2])
    end

    it "searches with username" do
      usernames = described_class.search_usernames(user1.username)
      expect(usernames.count).to eq(1)
      expect(usernames.map { |u| u["username"] }).to match([user1.username])
    end

    it "analyzes wildcards" do
      user3 = create(:user, username: "does_not_start_with_a_star")
      index_documents([user3])

      usernames = described_class.search_usernames("star*")
      expect(usernames.map { |u| u["username"] }).to match(
        [user1.username, user2.username],
      )
      expect(usernames.map { |u| u["username"] }).not_to include(user3.username)
    end

    it "does not allow leading wildcards" do
      expect { described_class.search_usernames("*star") }.to raise_error(Search::Errors::Transport::BadRequest)
    end

    it "limits the number of results to the value of MAX_RESULTS" do
      max_results = 1
      stub_const("Search::Postgres::Username::MAX_RESULTS", max_results)

      usernames = described_class.search_usernames("star*")
      expect(usernames.size).to eq(max_results)
      expect([user1.username, user2.username]).to include(usernames.first["username"])
    end
  end
end
