require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  subject { described_class.new(user, other_user) }

  let(:other_user) { create(:user) }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is signed-in" do
    let(:user) { other_user }

    permitted_actions = %i[
      edit analytics update onboarding_update join_org dashboard_show remove_identity destroy
    ]

    it { is_expected.to permit_actions(permitted_actions) }

    context "with suspended status" do
      before { user.add_role(:suspended) }

      it { is_expected.to forbid_actions(%i[join_org moderation_routes update]) }
    end
  end

  context "when user is trusted" do
    let(:user) { build(:user, :trusted) }

    it { is_expected.to permit_actions(%i[moderation_routes]) }
  end

  context "when user is not trusted" do
    let(:user) { build_stubbed(:user) }

    it { is_expected.to forbid_actions(%i[moderation_routes]) }
  end

  context "when the user is an admin" do
    let(:user) { build(:user, :admin) }

    it { is_expected.to permit_actions(%i[moderation_routes admin_delete]) }

    it "forbids admin_delete when targeting self" do
      expect(described_class.new(user, user)).to forbid_action(:admin_delete)
    end

    it "forbids admin_delete when targeting another admin or super admin" do
      expect(described_class.new(user, build(:user, :admin))).to forbid_action(:admin_delete)
      expect(described_class.new(user, build(:user, :super_admin))).to forbid_action(:admin_delete)
    end

    it "forbids admin_delete when target user has reached the published activity threshold" do
      create_list(:article, 3, user: other_user, published: true)
      create_list(:comment, 2, user: other_user, deleted: false)

      expect(described_class.new(user, other_user)).to forbid_action(:admin_delete)
    end

    it "permits admin_delete when unpublished drafts and deleted comments do not reach the published threshold" do
      create_list(:article, 2, user: other_user, published: true)
      create_list(:article, 4, user: other_user, published: false)
      create_list(:comment, 2, user: other_user, deleted: false)
      create_list(:comment, 3, user: other_user, deleted: true)

      expect(described_class.new(user, other_user)).to permit_action(:admin_delete)
    end
  end

  context "when the user is a super admin" do
    let(:user) { build(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[moderation_routes admin_delete]) }

    it "forbids admin_delete when targeting self" do
      expect(described_class.new(user, user)).to forbid_action(:admin_delete)
    end

    it "permits admin_delete even when target user exceeds the published activity threshold or is an admin" do
      create_list(:article, 5, user: other_user, published: true)

      expect(described_class.new(user, other_user)).to permit_action(:admin_delete)
      expect(described_class.new(user, build(:user, :admin))).to permit_action(:admin_delete)
    end
  end

  context "when the user is a moderator" do
    let(:user) { build(:user, :super_moderator) }

    it { is_expected.to permit_actions(%i[moderation_routes]) }
    it { is_expected.to forbid_actions(%i[admin_delete]) }
  end
end
