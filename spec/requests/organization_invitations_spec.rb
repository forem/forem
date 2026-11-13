require "rails_helper"

RSpec.describe "OrganizationInvitations" do
  let(:invitee) { create(:user) }
  let(:organization) { create(:organization) }
  let!(:membership) do
    create(:organization_membership, user: invitee, organization: organization, type_of_user: "pending")
  end

  before { Notifications::OrganizationInvitations::Send.call(membership) }

  describe "PATCH /organization_invitations/:id/accept" do
    context "when signed in as the invitee" do
      before { sign_in invitee }

      it "confirms the membership and redirects back to notifications", :aggregate_failures do
        patch accept_organization_invitation_path(membership)

        expect(membership.reload.type_of_user).to eq("member")
        expect(response).to redirect_to(notifications_path)
      end

      it "shows the outcome on the notification instead of the buttons", :aggregate_failures do
        patch accept_organization_invitation_path(membership)

        notification = Notification.find_by(user_id: invitee.id, notifiable: membership)
        expect(notification.read).to be(true)
        expect(notification.json_data.dig("organization_invitation", "status")).to eq("accepted")
      end

      it "cannot be answered twice" do
        patch accept_organization_invitation_path(membership)

        expect { patch accept_organization_invitation_path(membership) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "does not let another user answer the invitation", :aggregate_failures do
      sign_in create(:user)

      expect { patch accept_organization_invitation_path(membership) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(membership.reload.type_of_user).to eq("pending")
    end

    it "requires authentication" do
      patch accept_organization_invitation_path(membership)

      expect(response).to have_http_status(:found).or have_http_status(:unauthorized)
      expect(membership.reload.type_of_user).to eq("pending")
    end
  end

  describe "PATCH /organization_invitations/:id/decline" do
    before { sign_in invitee }

    it "removes the pending membership and its notification", :aggregate_failures do
      expect { patch decline_organization_invitation_path(membership) }
        .to change(OrganizationMembership, :count).by(-1)
        .and change(Notification, :count).by(-1)

      expect(response).to redirect_to(notifications_path)
    end
  end

  describe "GET /notifications" do
    before { sign_in invitee }

    it "renders the invitation with accept and decline actions", :aggregate_failures do
      get notifications_path

      expect(response.body).to include(organization.name)
      expect(response.body).to include(accept_organization_invitation_path(membership))
      expect(response.body).to include(decline_organization_invitation_path(membership))
    end
  end

  describe "POST /users/remove_from_org" do
    let(:admin) { create(:user) }

    before do
      create(:organization_membership, user: admin, organization: organization, type_of_user: "admin")
      sign_in admin
    end

    it "removes the invitee's notification when an admin withdraws the invitation", :aggregate_failures do
      expect do
        post "/users/remove_from_org", params: { user_id: invitee.id, organization_id: organization.id }
      end.to change(OrganizationMembership, :count).by(-1)
        .and change(Notification, :count).by(-1)
    end
  end
end
