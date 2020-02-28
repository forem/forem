require "rails_helper"

RSpec.describe Search::ChatChannelMembership, type: :service, elasticsearch: true do
  describe "::index" do
    it "indexes a chat_channel_membership to elasticsearch" do
      chat_channel_membership = create(:chat_channel_membership)
      expect { described_class.find_document(chat_channel_membership.id) }.to raise_error(Search::Errors::Transport::NotFound)
      described_class.index(chat_channel_membership.id, id: chat_channel_membership.id)
      expect(described_class.find_document(chat_channel_membership.id)).not_to be_nil
    end
  end

  describe "::find_document" do
    it "fetches a document for a given ID from elasticsearch" do
      chat_channel_membership = create(:chat_channel_membership)
      described_class.index(chat_channel_membership.id, id: chat_channel_membership.id)
      expect { described_class.find_document(chat_channel_membership.id) }.not_to raise_error
    end
  end

  describe "::delete_document" do
    it "deletes a document for a given ID from elasticsearch" do
      chat_channel_membership = create(:chat_channel_membership)
      index_documents(chat_channel_membership)
      expect { described_class.find_document(chat_channel_membership.id) }.not_to raise_error
      described_class.delete_document(chat_channel_membership.id)
      expect { described_class.find_document(chat_channel_membership.id) }.to raise_error(Search::Errors::Transport::NotFound)
    end
  end

  describe "::create_index" do
    it "creates an elasticsearch index with INDEX_NAME" do
      described_class.delete_index
      expect(Search::Client.indices.exists(index: described_class::INDEX_NAME)).to eq(false)
      described_class.create_index
      expect(Search::Client.indices.exists(index: described_class::INDEX_NAME)).to eq(true)
    end

    it "creates an elasticsearch index with name argument" do
      other_name = "random"
      expect(Search::Client.indices.exists(index: other_name)).to eq(false)
      described_class.create_index(index_name: other_name)
      expect(Search::Client.indices.exists(index: other_name)).to eq(true)

      # Have to cleanup index since it wont automatically be handled by our cluster class bc of the unexpected name
      described_class.delete_index(index_name: other_name)
    end
  end

  describe "::delete_index" do
    it "deletes an elasticsearch index with INDEX_NAME" do
      expect(Search::Client.indices.exists(index: described_class::INDEX_NAME)).to eq(true)
      described_class.delete_index
      expect(Search::Client.indices.exists(index: described_class::INDEX_NAME)).to eq(false)
    end

    it "deletes an elasticsearch index with name argument" do
      other_name = "random"
      described_class.create_index(index_name: other_name)
      expect(Search::Client.indices.exists(index: other_name)).to eq(true)

      described_class.delete_index(index_name: other_name)
      expect(Search::Client.indices.exists(index: other_name)).to eq(false)
    end
  end

  describe "::add_alias" do
    it "adds alias INDEX_ALIAS to elasticsearch index with INDEX_NAME" do
      Search::Client.indices.delete_alias(index: described_class::INDEX_NAME, name: described_class::INDEX_ALIAS)
      expect(Search::Client.indices.exists(index: described_class::INDEX_ALIAS)).to eq(false)
      described_class.add_alias
      expect(Search::Client.indices.exists(index: described_class::INDEX_ALIAS)).to eq(true)
    end

    it "adds custom alias to elasticsearch index with INDEX_NAME" do
      other_alias = "random"
      expect(Search::Client.indices.exists(index: other_alias)).to eq(false)
      described_class.add_alias(index_name: described_class::INDEX_NAME, index_alias: other_alias)
      expect(Search::Client.indices.exists(index: other_alias)).to eq(true)
    end
  end

  describe "::update_mappings" do
    it "updates index mappings for chat_channel_membership index", :aggregate_failures do
      other_name = "random"
      described_class.create_index(index_name: other_name)
      initial_mapping = Search::Client.indices.get_mapping(index: other_name).dig(other_name, "mappings")
      expect(initial_mapping).to be_empty

      described_class.update_mappings(index_alias: other_name)
      mapping = Search::Client.indices.get_mapping(index: other_name).dig(other_name, "mappings")
      expect(mapping.deep_stringify_keys).to include(described_class::MAPPINGS.deep_stringify_keys)

      # Have to cleanup index since it wont automatically be handled by our cluster class bc of the unexpected name
      described_class.delete_index(index_name: other_name)
    end
  end

  describe "::search_documents" do
    let(:user) { create(:user) }
    let(:chat_channel_membership1) { create(:chat_channel_membership, user_id: user.id) }
    let(:chat_channel_membership2) { create(:chat_channel_membership, user_id: user.id) }

    it "parses chat_channel_membership document hits from search response" do
      mock_search_response = { "hits" => { "hits" => {} } }
      allow(described_class).to receive(:search) { mock_search_response }
      described_class.search_documents(params: {}, user_id: 1)
      expect(described_class).to have_received(:search).with(body: a_kind_of(Hash))
    end

    context "with a query" do
      it "searches by channel_text" do
        allow(chat_channel_membership1).to receive(:channel_text).and_return("a name")
        allow(chat_channel_membership2).to receive(:channel_text).and_return("another name and slug")
        index_documents([chat_channel_membership1, chat_channel_membership2])
        name_params = { size: 5, channel_text: "name" }

        chat_channel_membership_docs = described_class.search_documents(params: name_params, user_id: user.id)
        expect(chat_channel_membership_docs.count).to eq(2)
        doc_ids = chat_channel_membership_docs.map { |t| t.dig("id") }
        expect(doc_ids).to include(chat_channel_membership1.id, chat_channel_membership2.id)
      end
    end

    context "with a filter" do
      it "searches by viewable_by" do
        new_user = create(:user)
        chat_channel_membership3 = create(:chat_channel_membership, user_id: new_user.id)
        index_documents([chat_channel_membership1, chat_channel_membership2, chat_channel_membership3])
        params = { size: 5 }

        chat_channel_membership_docs = described_class.search_documents(params: params, user_id: new_user.id)
        expect(chat_channel_membership_docs.count).to eq(1)
        expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership3.id)
      end

      it "searches by channel_status" do
        allow(chat_channel_membership1).to receive(:channel_status).and_return("popping")
        index_documents([chat_channel_membership1, chat_channel_membership2])
        params = { size: 5, channel_status: "popping" }

        chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
        expect(chat_channel_membership_docs.count).to eq(1)
        expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership1.id)
      end

      it "searches by channel_type" do
        allow(chat_channel_membership2).to receive(:channel_type).and_return("invite_only")
        index_documents([chat_channel_membership1, chat_channel_membership2])
        params = { size: 5, channel_type: "invite_only" }

        chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
        expect(chat_channel_membership_docs.count).to eq(1)
        expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership2.id)
      end

      it "only returns active status memberships" do
        chat_channel_membership1.update(status: "inactive")
        chat_channel_membership2.update(status: "active")
        index_documents([chat_channel_membership1, chat_channel_membership2])
        params = { size: 5 }

        chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
        expect(chat_channel_membership_docs.count).to eq(1)
        expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership2.id)
      end
    end

    context "with a query and filter" do
      it "searches by channel_text and status" do
        allow(chat_channel_membership1).to receive(:channel_text).and_return("a name")
        allow(chat_channel_membership2).to receive(:channel_text).and_return("another name")
        chat_channel_membership1.update(status: "active")
        chat_channel_membership2.update(status: "inactive")
        index_documents([chat_channel_membership1, chat_channel_membership2])
        name_params = { size: 5, channel_text: "name", status: "active" }

        chat_channel_membership_docs = described_class.search_documents(params: name_params, user_id: user.id)
        expect(chat_channel_membership_docs.count).to eq(1)
        doc_ids = chat_channel_membership_docs.map { |t| t.dig("id") }
        expect(doc_ids).to include(chat_channel_membership1.id)
      end
    end

    it "sorts documents for given field" do
      allow(chat_channel_membership1).to receive(:channel_type).and_return("not_direct")
      allow(chat_channel_membership2).to receive(:channel_type).and_return("direct")
      index_documents([chat_channel_membership1, chat_channel_membership2])
      params = { size: 5, sort_by: "channel_type", sort_direction: "asc" }

      chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
      expect(chat_channel_membership_docs.count).to eq(2)
      expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership2.id)
      expect(chat_channel_membership_docs.last["id"]).to eq(chat_channel_membership1.id)
    end

    it "sorts documents by channel_last_message_at by default" do
      allow(chat_channel_membership1).to receive(:channel_last_message_at).and_return(Time.current)
      allow(chat_channel_membership2).to receive(:channel_last_message_at).and_return(1.year.ago)
      index_documents([chat_channel_membership1, chat_channel_membership2])
      params = { size: 5 }

      chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
      expect(chat_channel_membership_docs.count).to eq(2)
      expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership1.id)
      expect(chat_channel_membership_docs.last["id"]).to eq(chat_channel_membership2.id)
    end

    it "will return a set number of docs based on pagination params" do
      index_documents([chat_channel_membership1, chat_channel_membership2])
      params = { page: 0, per_page: 1 }

      chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
      expect(chat_channel_membership_docs.count).to eq(1)
    end

    it "paginates the results" do
      allow(chat_channel_membership1).to receive(:channel_last_message_at).and_return(Time.current)
      allow(chat_channel_membership2).to receive(:channel_last_message_at).and_return(1.year.ago)
      index_documents([chat_channel_membership1, chat_channel_membership2])
      first_page_params = { page: 0, per_page: 1, sort_by: "channel_last_message_at", order: "dsc" }

      chat_channel_membership_docs = described_class.search_documents(params: first_page_params, user_id: user.id)
      expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership1.id)

      second_page_params = { page: 1, per_page: 1, sort_by: "channel_last_message_at", order: "dsc" }

      chat_channel_membership_docs = described_class.search_documents(params: second_page_params, user_id: user.id)
      expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership2.id)
    end

    it "returns an empty Array if no results are found" do
      allow(chat_channel_membership1).to receive(:channel_last_message_at).and_return(Time.current)
      allow(chat_channel_membership2).to receive(:channel_last_message_at).and_return(1.year.ago)
      index_documents([chat_channel_membership1, chat_channel_membership2])
      params = { page: 3, per_page: 1 }

      chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
      expect(chat_channel_membership_docs).to eq([])
    end
  end
end
