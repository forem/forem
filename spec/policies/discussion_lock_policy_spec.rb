require "rails_helper"

RSpec.describe DiscussionLockPolicy do
  subject { described_class.new(user, article) }

  let!(:user) { create(:user) }
  let(:article) { build_stubbed(:article) }
  let(:valid_attributes) { %i[article_id reason] }

  before { allow(article).to receive(:published).and_return(true) }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not the author" do
    it { is_expected.to forbid_actions(%i[create destroy]) }
  end

  context "when user is the author" do
    let(:article) { build_stubbed(:article, user: user) }

    it { is_expected.to permit_actions(%i[create destroy]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end

  context "when user is an admin" do
    let(:user) { build(:user, :admin) }

    it { is_expected.to permit_actions(%i[create destroy]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end

  context "when user is a super_admin" do
    let(:user) { build(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[create destroy]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end
end
