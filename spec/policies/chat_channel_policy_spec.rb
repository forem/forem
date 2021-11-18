require "rails_helper"

RSpec.describe ChatChannelPolicy, type: :policy do
  subject { described_class.new(user, chat_channel) }

  let(:chat_channel) { build_stubbed(:chat_channel, channel_type: "invite_only") }
  let!(:user) { create(:user) }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not a part of channel" do
    it { is_expected.to permit_actions(%i[index]) }
    it { is_expected.to forbid_actions(%i[show open moderate update]) }
  end

  context "when user is a part of channel" do
    before { allow(chat_channel).to receive(:has_member?).with(user).and_return(true) }

    it { is_expected.to permit_actions(%i[index show open]) }
    it { is_expected.to forbid_actions(%i[moderate update]) }
  end

  context "when user is an admin but not part of channel" do
    before { user.add_role(:super_admin) }

    it { is_expected.to permit_actions(%i[index update]) }
    it { is_expected.to forbid_actions(%i[show open]) }
  end
end
