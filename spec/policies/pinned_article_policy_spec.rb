require "rails_helper"

RSpec.describe PinnedArticlePolicy, type: :policy do
  subject { described_class.new(user, nil) }

  context "when user is not signed in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is signed in as a regular user" do
    let(:user) { build_stubbed(:user) }

    it { is_expected.to forbid_actions(%i[show update destroy]) }
  end

  context "when user is signed in as an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_actions(%i[show update destroy]) }
  end

  context "when user is signed in as a super_admin" do
    let(:user) { create(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[show update destroy]) }
  end
end
