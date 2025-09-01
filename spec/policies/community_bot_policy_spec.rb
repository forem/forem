require "rails_helper"

RSpec.describe CommunityBotPolicy, type: :policy do
  subject { described_class.new(user, record) }

  let(:subforem) { create(:subforem) }
  let(:bot_user) { create(:user, type_of: :community_bot, onboarding_subforem_id: subforem.id) }
  let(:admin_user) { create(:user, :super_admin) }
  let(:super_moderator) { create(:user, :super_moderator) }
  let(:moderator_user) { create(:user) }
  let(:regular_user) { create(:user) }

  before do
    allow(moderator_user).to receive(:subforem_moderator?).with(subforem: subforem).and_return(true)
  end

  context "when record is a User (bot)" do
    let(:record) { bot_user }

    context "when user is a super admin" do
      let(:user) { admin_user }

      it { is_expected.to permit_actions %i[index new create show destroy] }
    end

    context "when user is a super moderator" do
      let(:user) { super_moderator }

      it { is_expected.to permit_actions %i[index new create show destroy] }
    end

    context "when user is a subforem moderator" do
      let(:user) { moderator_user }

      it { is_expected.to permit_actions %i[index new create show destroy] }
    end

    context "when user is a regular user" do
      let(:user) { regular_user }

      it { is_expected.to forbid_actions %i[index new create show destroy] }
    end

    context "when user is not signed in" do
      let(:user) { nil }

      it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
    end
  end

  context "when record is a Subforem" do
    let(:record) { subforem }

    context "when user is a super admin" do
      let(:user) { admin_user }

      it { is_expected.to permit_actions %i[index new create show destroy] }
    end

    context "when user is a super moderator" do
      let(:user) { super_moderator }

      it { is_expected.to permit_actions %i[index new create show destroy] }
    end

    context "when user is a subforem moderator" do
      let(:user) { moderator_user }

      it { is_expected.to permit_actions %i[index new create show destroy] }
    end

    context "when user is a regular user" do
      let(:user) { regular_user }

      it { is_expected.to forbid_actions %i[index new create show destroy] }
    end
  end

  context "when record is a regular user (not a bot)" do
    let(:record) { regular_user }

    context "when user is a super admin" do
      let(:user) { admin_user }

      it { is_expected.to permit_actions %i[index new create show destroy] }
    end

    context "when user is a regular user" do
      let(:user) { regular_user }

      it { is_expected.to forbid_actions %i[index new create show destroy] }
    end
  end
end


