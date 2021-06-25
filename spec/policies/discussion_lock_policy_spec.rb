require "rails_helper"

RSpec.describe DiscussionLockPolicy do
  subject { described_class.new(locking_user, discussion_lock) }

  let!(:locking_user) { create(:user) }
  let(:article) { build_stubbed(:article, user: locking_user) }
  let(:discussion_lock) { build_stubbed(:discussion_lock, locking_user: locking_user, article: article) }
  let(:valid_attributes) { %i[article_id notes reason] }

  context "when user is not signed-in" do
    let(:locking_user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not the author" do
    let(:user) { build_stubbed(:user) }
    let(:discussion_lock) { build_stubbed(:discussion_lock, locking_user: user, article: article) }

    it { is_expected.to forbid_actions(%i[create destroy]) }
  end

  context "when user is the author" do
    let(:article) { build_stubbed(:article, user: locking_user) }

    it { is_expected.to permit_actions(%i[create destroy]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end

  context "when user is suspended" do
    let(:user) { build_stubbed(:user, :suspended) }
    let(:discussion_lock) { build_stubbed(:discussion_lock, locking_user: user, article: article) }

    it { is_expected.to forbid_actions(%i[create destroy]) }
  end

  context "when user is an admin" do
    let(:locking_user) { build(:user, :admin) }

    it { is_expected.to permit_actions(%i[create destroy]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end

  context "when user is a super_admin" do
    let(:locking_user) { build(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[create destroy]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end
end
