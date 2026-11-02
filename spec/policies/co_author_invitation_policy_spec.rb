require "rails_helper"

RSpec.describe CoAuthorInvitationPolicy, type: :policy do
  let(:invitation) { create(:co_author_invitation) }

  context "when user is not signed in" do
    subject { described_class.new(nil, invitation) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is the invitee" do
    subject(:policy) { described_class.new(invitation.user, invitation) }

    it { is_expected.to permit_actions(%i[accept decline candidates]) }

    context "when the invitee is suspended" do
      before { invitation.user.add_role(:suspended) }

      it { is_expected.to permit_actions(%i[decline]) }

      it "does not let them accept" do
        expect { policy.accept? }.to raise_error(ApplicationPolicy::UserSuspendedError)
      end
    end
  end

  context "when user is someone else, including the author" do
    subject { described_class.new(invitation.article.user, invitation) }

    it { is_expected.to forbid_actions(%i[accept decline]) }
  end
end
