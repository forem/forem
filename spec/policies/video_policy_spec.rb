require "rails_helper"

RSpec.describe VideoPolicy do
  let(:user) { User.new }
  let(:policy) { described_class.new(user, nil) }
  let(:enabled) { true }
  let(:limit_post_creation_to_admins) { false }

  before do
    allow(Settings::General).to receive(:enable_video_upload).and_return(enabled)
    allow(ArticlePolicy).to receive(:limit_post_creation_to_admins?).and_return(limit_post_creation_to_admins)
  end

  describe "#create?" do
    subject(:predicate) { policy.create? }

    context "when user is suspended" do
      let(:enabled) { true }
      let(:user) { create(:user, :suspended) }

      it { within_block_is_expected.to raise_error(ApplicationPolicy::UserSuspendedError) }
    end

    context "when user is not signed-in" do
      let(:enabled) { true }
      let(:user) { nil }

      it { within_block_is_expected.to raise_error(ApplicationPolicy::UserRequiredError) }
    end

    context "when user has been registered for awhile" do
      let(:user) { build(:user) }

      before { user.created_at = 3.weeks.ago }

      it { is_expected.to be_truthy }
    end

    context "when user has just registered" do
      let(:enabled) { true }
      let(:user) { build(:user) }

      before { user.created_at = 1.hour.ago }

      it { is_expected.to be_falsey }
    end

    context "when video upload is not enabled" do
      let(:enabled) { false }
      let(:user) { build(:user) }

      before { user.created_at = 1.hour.ago }

      it { is_expected.to be_falsey }
    end

    context "when limit_post_creation_to_admins and user not admin" do
      let(:limit_post_creation_to_admins) { true }
      let(:user) { build(:user) }

      before { user.created_at = 3.weeks.ago }

      it { is_expected.to be_falsey }
    end

    context "when limit_post_creation_to_admins and user is a new admin" do
      let(:limit_post_creation_to_admins) { true }
      let(:user) { build(:user, :admin) }

      before { user.created_at = 1.week.ago }

      it { is_expected.to be_truthy }
    end
  end
end
