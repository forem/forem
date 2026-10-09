require "rails_helper"

RSpec.describe "CoAuthorInvitations" do
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }
  let(:invitee) { create(:user) }

  describe "GET /co_author_invitations/candidates" do
    let(:follower) { create(:user, name: "Ada Follower", username: "ada_follower") }
    let(:stranger) { create(:user, name: "Ada Stranger", username: "ada_stranger") }

    before do
      follower.follow(author)
      stranger
      sign_in author
    end

    it "is not found while the feature is disabled" do
      expect { get candidates_co_author_invitations_path, params: { search: "ada" } }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when the feature is enabled" do
      before { FeatureFlag.enable(:co_author_invitations) }

      it "returns matching followers only", :aggregate_failures do
        get candidates_co_author_invitations_path, params: { search: "ada" }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.pluck("username")).to eq(["ada_follower"])
        expect(response.parsed_body.first.keys).to contain_exactly("id", "name", "username", "profile_image_90")
      end

      it "returns nothing for a blank search" do
        get candidates_co_author_invitations_path, params: { search: "" }

        expect(response.parsed_body).to eq([])
      end
    end
  end

  describe "PATCH /co_author_invitations/:id/accept" do
    let(:invitation) { create(:co_author_invitation, article: article, user: invitee) }

    it "credits the invitee and returns to their notifications", :aggregate_failures do
      sign_in invitee

      patch accept_co_author_invitation_path(invitation)

      expect(response).to redirect_to(notifications_path)
      expect(invitation.reload).to be_accepted
      expect(article.reload.co_author_ids).to eq([invitee.id])
    end

    it "works regardless of the feature flag, so existing invitations can always be answered" do
      FeatureFlag.disable(:co_author_invitations)
      sign_in invitee

      patch accept_co_author_invitation_path(invitation)

      expect(invitation.reload).to be_accepted
    end

    it "responds with the new status as JSON" do
      sign_in invitee

      patch accept_co_author_invitation_path(invitation), as: :json

      expect(response.parsed_body).to eq("status" => "accepted")
    end

    it "flashes an error when the invitation was already answered", :aggregate_failures do
      invitation.update!(status: :declined)
      sign_in invitee

      patch accept_co_author_invitation_path(invitation)

      expect(flash[:global_notice]).to be_present
      expect(invitation.reload).to be_declined
    end

    it "does not let anyone else accept it", :aggregate_failures do
      sign_in author

      expect { patch accept_co_author_invitation_path(invitation) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(invitation.reload).to be_pending
    end

    it "does not let a suspended invitee accept it" do
      invitation
      invitee.add_role(:suspended)
      sign_in invitee

      expect { patch accept_co_author_invitation_path(invitation) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "requires a signed-in user" do
      patch accept_co_author_invitation_path(invitation)

      expect(response).to redirect_to(new_magic_link_path)
    end
  end

  describe "PATCH /co_author_invitations/:id/decline" do
    it "declines a pending invitation" do
      invitation = create(:co_author_invitation, article: article, user: invitee)
      sign_in invitee

      patch decline_co_author_invitation_path(invitation)

      expect(invitation.reload).to be_declined
    end

    it "removes the credit from an accepted invitation", :aggregate_failures do
      invitation = create(:co_author_invitation, :accepted, article: article, user: invitee)
      sign_in invitee

      patch decline_co_author_invitation_path(invitation)

      expect(invitation.reload).to be_declined
      expect(article.reload.co_author_ids).to eq([])
    end
  end
end
