require "rails_helper"

RSpec.describe Users::ApprovedLiquidTags, type: :service do
  subject { described_class.call(user) }

  context "when user is admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to match([UserSubscriptionTag]) }
  end

  context "when user has no role" do
    let(:user) { create(:user) }

    it { is_expected.to be_empty }
  end
end
