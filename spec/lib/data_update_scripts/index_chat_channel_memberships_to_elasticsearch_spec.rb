require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200218195023_index_chat_channel_memberships_to_elasticsearch.rb")

describe DataUpdateScripts::IndexChatChannelMembershipsToElasticsearch, elasticsearch: true do
  it "indexes chat channel memberships to Elasticsearch" do
    chat_channel_membership = FactoryBot.create(:chat_channel_membership)
    expect { chat_channel_membership.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    described_class.new.run
    expect(chat_channel_membership.elasticsearch_doc).not_to be_nil
  end
end
