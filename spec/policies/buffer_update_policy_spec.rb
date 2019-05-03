require "rails_helper"

RSpec.describe BufferUpdatePolicy do
  subject { described_class.new(user, article) }

  let(:article) { build(:article) }

  context "when user is trusted" do
    let(:user) { build(:user, :trusted) }

    it { is_expected.to permit_actions(%i[create]) }
  end
end
