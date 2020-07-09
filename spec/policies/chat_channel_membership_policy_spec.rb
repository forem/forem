require "rails_helper"

RSpec.describe ChatChannelMembershipPolicy, type: :policy do
  subject { described_class.new(user, chat_channel_membership) }

  let(:user)                    { build_stubbed(:user) }
  let(:chat_channel)            { build_stubbed(:chat_channel) }

  context "when user is not signed-in" do
    let(:user) { nil }
    let(:chat_channel_membership) { build_stubbed(:chat_channel_membership) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user belongs to membership" do
    let(:chat_channel_membership) { build_stubbed(:chat_channel_membership, user: user, chat_channel: chat_channel) }

    it { is_expected.to permit_actions(%i[update destroy]) }
  end

  context "when user does not belong to membership" do
    let(:other_user) { build_stubbed(:user) }
    let(:chat_channel_membership) do
      build_stubbed(:chat_channel_membership, user: other_user, chat_channel: chat_channel)
    end

    it { is_expected.to forbid_actions(%i[update destroy]) }
  end
end
