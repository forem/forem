require "rails_helper"

RSpec.describe ChatChannelPolicy do
  subject { described_class.new(user, chat_channel) }

  let(:chat_channel) { create(:chat_channel, channel_type: "invite_only") }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not a part of channel" do
    let(:user) { build(:user) }
    it { is_expected.to permit_actions(%i[index]) }
    it { is_expected.to forbid_actions(%i[show open moderate]) }
  end

  context "when user is a part of channel" do
    let(:user) { create(:user) }
    before { chat_channel.add_users [user] }
    it { is_expected.to permit_actions(%i[index show open]) }
    it { is_expected.to forbid_actions(%i[moderate]) }
  end

  context "when user is an admin but not part of channel" do
    let(:user) { create(:user) }
    before { user.add_role(:super_admin) }
    it { is_expected.to permit_actions(%i[index moderate]) }
    it { is_expected.to forbid_actions(%i[show open]) }
  end
end
