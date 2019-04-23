require "rails_helper"

RSpec.describe BufferUpdatePolicy do
  subject { described_class.new(user, block) }

  let(:block) { build(:block) }

  context "when user is trusted" do
    let(:user) { build(:user, :trusted) }

    it { is_expected.to permit_actions(%i[create]) }
  end

  context "when user is not trusted" do
    let(:user) { build(:user) }

    it { is_expected.to forbid_actions(%i[create]) }
  end
end
