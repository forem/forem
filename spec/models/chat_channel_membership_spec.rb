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
end
