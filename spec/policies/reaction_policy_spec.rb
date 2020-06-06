require "rails_helper"

RSpec.describe ReactionPolicy do
  subject { described_class.new(user, reaction) }

  let_it_be(:comment) { create(:comment, commentable: create(:article)) }
  let_it_be(:reaction) { create(:reaction, reactable: comment) }
  let!(:user) { create(:user) }

  context "when user is not signed in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is signed in" do
    it { is_expected.to permit_actions(%i[index create]) }

    context "when user is banned" do
      before { user.add_role_synchronously(:banned) }

      it { is_expected.to permit_actions(%i[index]) }
      it { is_expected.to forbid_actions(%i[create]) }
    end
  end
end
