require "rails_helper"

RSpec.describe ChatChannelMembership, type: :model do
  let(:chat_channel_membership) { FactoryBot.create(:chat_channel_membership) }

  describe "#channel_text" do
    it "sets channel text using name, slug, and human names" do
      chat_channel = chat_channel_membership.chat_channel
      parsed_channel_name = chat_channel_membership.channel_name&.gsub("chat between", "")&.gsub("and", "")
      expected_text = "#{parsed_channel_name} #{chat_channel.slug} #{chat_channel.channel_human_names.join(' ')}"
      expect(chat_channel_membership.channel_text).to eq(expected_text)
    end
  end

  describe "#index_to_elasticsearch" do
    it "enqueues job to index tag to elasticsearch" do
      sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker, args: [described_class.to_s, chat_channel_membership.id]) do
        chat_channel_membership.index_to_elasticsearch
      end
    end
  end

  describe "#index_to_elasticsearch_inline" do
    it "indexed chat_channel_membership to elasticsearch inline" do
      allow(Search::ChatChannelMembership).to receive(:index)
      chat_channel_membership.index_to_elasticsearch_inline
      expect(Search::ChatChannelMembership).to have_received(:index).with(chat_channel_membership.id, hash_including(:id, :channel_name))
    end
  end

  describe "#after_commit" do
    it "on update enqueues job to index chat_channel_membership to elasticsearch" do
      chat_channel_membership.save
      sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker, args: [described_class.to_s, chat_channel_membership.id]) do
        chat_channel_membership.save
      end
    end

    it "on destroy enqueues job to delete chat_channel_membership from elasticsearch" do
      chat_channel_membership.save
      sidekiq_assert_enqueued_with(job: Search::RemoveFromElasticsearchIndexWorker, args: [described_class::SEARCH_CLASS.to_s, chat_channel_membership.id]) do
        chat_channel_membership.destroy
      end
    end
  end

  describe "#serialized_search_hash" do
    it "creates a valid serialized hash to send to elasticsearch" do
      mapping_keys = Search::ChatChannelMembership::MAPPINGS.dig(:properties).keys
      expect(chat_channel_membership.serialized_search_hash.symbolize_keys.keys).to eq(mapping_keys)
    end
  end

  describe "#elasticsearch_doc" do
    it "finds document in elasticsearch", elasticsearch: true do
      allow(Search::ChatChannelMembership).to receive(:find_document)
      chat_channel_membership.elasticsearch_doc
      expect(Search::ChatChannelMembership).to have_received(:find_document)
    end
  end
end
