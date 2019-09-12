require "rails_helper"

RSpec.describe Internal::ArticlePolicy do
  subject { described_class.new(user, article) }

  let(:article) { build(:article) }
  let(:user) { build_stubbed(:user) }

  context "when regular user" do
    it { is_expected.to forbid_actions(%i[index show update]) }
  end

  context "when user is a dev intern" do
    before { allow(user).to receive(:has_role?).with(:intern).and_return(true) }

    it { is_expected.to permit_actions(%i[index show update]) }
  end
end
