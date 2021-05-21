require "rails_helper"

RSpec.describe Search::ChatChannelMembershipSerializer do
  let(:ccm) { create(:chat_channel_membership) }

  it "serializes a ChatChannelMembership" do
    data_hash = described_class.new(ccm).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(
      :id, :status, :viewable_by, :chat_channel_id, :last_opened_at, :channel_text,
      :channel_last_message_at, :channel_status, :channel_type, :channel_username, :channel_name,
      :channel_image, :channel_modified_slug, :channel_discoverable, :channel_messages_count
    )
  end
end
