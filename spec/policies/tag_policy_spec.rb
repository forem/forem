require "rails_helper"

RSpec.describe TagPolicy, type: :policy do
  subject { described_class.new(user, tag) }

  let(:tag) { build_stubbed(:tag) }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not a moderator" do
    let(:user) { build_stubbed(:user) }

    it { is_expected.to permit_actions(%i[index]) }
    it { is_expected.to forbid_actions(%i[edit update]) }
  end
end
