require "rails_helper"

RSpec.describe StripeSubscriptionPolicy do
  subject { described_class.new(user, :stripe_subscription) }

  context "when user is not signed in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is signed in" do
    let(:user) { build(:user) }

    it { is_expected.to permit_actions(%i[create update destroy]) }

    context "when user is banned" do
      let(:user) { build(:user, :banned) }

      it { is_expected.to forbid_actions(%i[create update]) }
    end
  end
end
