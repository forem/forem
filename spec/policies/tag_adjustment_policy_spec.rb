require "rails_helper"

RSpec.describe TagAdjustmentPolicy, type: :policy do
  subject { described_class.new(user, tag_adjustment) }

  let(:tag) { create(:tag) }
  let(:creator) { create(:user, :trusted) }
  let(:tag_adjustment) { build_stubbed(:tag_adjustment, user: creator, tag: tag) }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(ApplicationPolicy::UserRequiredError) }
  end

  context "when user is a regular trusted member" do
    let(:user) { create(:user, :trusted) }

    it { is_expected.to forbid_action(:destroy) }
  end

  context "when user is an admin in good standing" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:destroy) }
  end

  context "when user is a super moderator in good standing" do
    let(:user) { create(:user, :super_moderator) }

    it { is_expected.to permit_action(:destroy) }
  end

  context "when user is suspended" do
    let(:user) { create(:user, :admin, :suspended) }

    it "raises ApplicationPolicy::UserSuspendedError on destroy?" do
      expect { described_class.new(user, tag_adjustment).destroy? }
        .to raise_error(ApplicationPolicy::UserSuspendedError)
    end
  end

  context "when user is a trusted tag moderator for the adjustment's tag" do
    let(:user) { creator }

    before { user.add_role(:tag_moderator, tag) }

    it { is_expected.to permit_action(:destroy) }

    context "when the adjustment belongs to another user" do
      let(:other_user) { create(:user) }
      let(:tag_adjustment) { build_stubbed(:tag_adjustment, user: other_user, tag: tag) }

      it { is_expected.to forbid_action(:destroy) }
    end
  end

  context "when user holds the tag moderator role but is not trusted" do
    let(:creator) { create(:user) }
    let(:user) { creator }

    before { user.add_role(:tag_moderator, tag) }

    it { is_expected.to forbid_action(:destroy) }
  end

  context "when user is a community leader without a tag moderator role for the tag" do
    let(:creator) { create(:user, :trusted, :community_leader_level_1) }
    let(:user) { creator }

    it { is_expected.to forbid_action(:destroy) }
  end

  context "when user created the adjustment but is no longer a tag moderator for that tag" do
    let(:user) { creator }

    it { is_expected.to forbid_action(:destroy) }
  end

  context "when the adjustment has no associated tag" do
    let(:tag_adjustment) { build_stubbed(:tag_adjustment, user: creator, tag: nil) }

    context "when user is the creator with a tag moderator role on another tag" do
      let(:user) { creator }

      before { user.add_role(:tag_moderator, tag) }

      it { is_expected.to forbid_action(:destroy) }
    end

    context "when user is an admin in good standing" do
      let(:user) { create(:user, :admin) }

      it { is_expected.to permit_action(:destroy) }
    end
  end
end
