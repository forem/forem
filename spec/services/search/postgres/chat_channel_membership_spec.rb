require "rails_helper"

RSpec.describe Search::Postgres::ChatChannelMembership, type: :service do
  let(:user) { create(:user) }

  describe "::search_documents" do
    it "does not include chat channel memberships that are not included in permitted statuses", :aggregate_failures do
      ccm = create(:chat_channel_membership, user: user)
      rejected_ccm = create(:chat_channel_membership, user: user, status: "rejected")
      result = described_class.search_documents(user_ids: [user.id])
      # rubocop:disable Rails/PluckId
      ids = result.pluck(:id)
      # rubocop:enable Rails/PluckId

      expect(ids).not_to include(rejected_ccm.id)
      expect(ids).to include(ccm.id)
    end

    context "when describing the result format" do
      before { create(:chat_channel_membership, status: "active", user: user) }

      it "returns the correct attributes for the result" do
        result = described_class.search_documents(user_ids: [user.id])
        expected_keys = %i[
          id status viewable_by chat_channel_id last_opened_at channel_text channel_last_message_at
          channel_status channel_type channel_username channel_name channel_image
          channel_modified_slug channel_discoverable channel_messages_count
        ]

        expect(result.first.keys).to match_array(expected_keys)
      end
    end
  end

  it "orders the results by chat_channel.last_message at in descending order" do
    cc_older = create(:chat_channel, last_message_at: 1.hour.ago)
    cc_newer = create(:chat_channel, last_message_at: Time.zone.now)
    ccm_older = create(:chat_channel_membership, user: user, chat_channel: cc_older)
    ccm_newer = create(:chat_channel_membership, user: user, chat_channel: cc_newer)
    result = described_class.search_documents(user_ids: [user.id])

    # rubocop:disable Rails/PluckId
    ids = result.pluck(:id)
    # rubocop:enable Rails/PluckId

    expect(ids).to eq([ccm_newer.id, ccm_older.id])
  end
end
