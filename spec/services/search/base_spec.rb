require "rails_helper"

RSpec.describe Search::Base, type: :service, elasticsearch: true do
  let(:document_id) { 123 }

  before do
    # Need to use an existing index name to ensure proper data cleanup
    stub_const("#{described_class}::INDEX_NAME", "tags_#{Rails.env}")
    stub_const("#{described_class}::INDEX_ALIAS", "tags_#{Rails.env}_alias")
    stub_const("#{described_class}::MAPPINGS", Search::Tag::MAPPINGS)
    allow(described_class).to receive(:index_settings).and_return({})
  end

  describe "::index" do
    it "indexes a document to elasticsearch" do
      expect { described_class.find_document(document_id) }.to raise_error(Search::Errors::Transport::NotFound)
      described_class.index(document_id, id: document_id)
      expect(described_class.find_document(document_id)).not_to be_nil
    end

    it "sets last_indexed_at field" do
      Timecop.freeze(Time.current) do
        described_class.index(document_id, id: document_id)
        last_indexed_at = described_class.find_document(document_id).dig("_source", "last_indexed_at")
        expect(Time.zone.parse(last_indexed_at).to_i).to eq(Time.current.to_i)
      end
    end
  end

  describe "::find_document" do
    it "fetches a document for a given ID from elasticsearch" do
      described_class.index(document_id, id: document_id)
      expect { described_class.find_document(document_id) }.not_to raise_error
    end
  end

  describe "::delete_document" do
    it "deletes a document for a given ID from elasticsearch" do
      described_class.index(document_id, id: document_id)
      expect { described_class.find_document(document_id) }.not_to raise_error
      described_class.delete_document(document_id)
      expect { described_class.find_document(document_id) }.to raise_error(Search::Errors::Transport::NotFound)
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
    it "updates index mappings" do
      other_name = "index_name"
      allow(Search::Client.indices).to receive(:put_mapping)

      described_class.update_mappings(index_alias: other_name)
      expect(Search::Client.indices).to have_received(:put_mapping).with(
        index: other_name, body: described_class::MAPPINGS,
      )
    end
  end
end
