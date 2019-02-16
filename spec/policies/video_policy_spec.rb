require "rails_helper"

RSpec.describe VideoPolicy do
  subject { described_class.new(user, nil) }

  let(:user) { User.new }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user does not have video permission" do
    let(:user) { build(:user) }

    it { is_expected.to forbid_actions(%i[new create]) }
  end

  context "when does have video permission" do
    let(:user) { build(:user) }

    before { user.created_at = 3.weeks.ago }

    it { is_expected.to permit_actions(%i[new create]) }
  end
end
