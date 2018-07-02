require "rails_helper"

RSpec.describe ChatChannelMembershipPolicy do
  subject { described_class.new(user, chat_channel_membership) }

  let(:chat_channel_membership) { build(:chat_channel_membership) }


  context "when user is not signed-in" do
    let(:user) { nil }
    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user belongs to membership" do
    let(:user) { create(:user) }
    let(:chat_channel) { create(:chat_channel ) }
    let(:chat_channel_membership) { create(:chat_channel_membership, user_id: user.id, chat_channel_id: chat_channel.id ) }
    it { is_expected.to permit_actions(%i[update]) }
  end
  context "when user does not belong to membership" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:chat_channel) { create(:chat_channel ) }
    let(:chat_channel_membership) { create(:chat_channel_membership, user_id: other_user.id, chat_channel_id: chat_channel.id ) }
    it { is_expected.to forbid_actions(%i[update]) }
  end
end