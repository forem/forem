require "rails_helper"

RSpec.describe BufferUpdatePolicy, type: :policy do
  subject { described_class.new(user, article) }

  let(:article) { build_stubbed(:article) }

  context "when user is trusted" do
    let(:user) { create(:user, :trusted) }

    it { is_expected.to permit_actions(%i[create]) }
  end
end
