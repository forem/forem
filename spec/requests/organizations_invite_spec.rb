require "rails_helper"

RSpec.describe "Organizations Invite" do
  let(:admin_user) { create(:user, :without_profile, profile_image: nil) }
  let(:organization) { create(:organization) }
  let(:invited_user) { create(:user, :without_profile, profile_image: nil) }

  before do
    create(:organization_membership, user: admin_user, organization: organization, type_of_user: "admin")
    sign_in admin_user
  end

  def seed_pending_invitations(count, base_time:, step: 1.minute)
    now = Time.current
    users = Array.new(count) do |i|
      slug = "pending_invite_#{SecureRandom.hex(6)}_#{i}"
      { name: "Pending Invite #{i}", username: slug, email: "#{slug}@example.com",
        registered: true, created_at: now, updated_at: now }
    end
    user_ids = User.insert_all(users, returning: %i[id]).rows.flatten
    OrganizationMembership.insert_all(
      user_ids.each_with_index.map do |user_id, i|
        timestamp = base_time + (i * step)
        { user_id: user_id, organization_id: organization.id, type_of_user: "pending",
          invitation_token: SecureRandom.urlsafe_base64(32), created_at: timestamp, updated_at: timestamp }
      end,
    )
  end

  describe "POST /organizations/:id/invite" do
    context "when organization is not fully trusted" do
      it "creates a pending membership" do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.to change(OrganizationMembership, :count).by(1)

        membership = OrganizationMembership.last
        expect(membership.user).to eq(invited_user)
        expect(membership.organization).to eq(organization)
        expect(membership.type_of_user).to eq("pending")
        expect(membership.invitation_token).to be_present
      end

      it "sends an invitation email" do
        mail_double = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
        mailer = Struct.new(:invitation_email).new(mail_double)
        allow(OrganizationInvitationMailer).to receive(:with).and_return(mailer)

        post organization_invite_path(organization.id), params: { username: invited_user.username }

        expect(OrganizationInvitationMailer).to have_received(:with).with(membership_id: kind_of(Integer))
        expect(mail_double).to have_received(:deliver_now)
      end

      it "redirects with success message" do
        post organization_invite_path(organization.id), params: { username: invited_user.username }
        expect(response).to redirect_to(organization_settings_path(organization.slug, anchor: "section-invitations"))
        expect(flash[:settings_notice]).to include("Successfully invited")
      end

      it "handles username with @ symbol" do
        expect do
          post organization_invite_path(organization.id), params: { username: "@#{invited_user.username}" }
        end.to change(OrganizationMembership, :count).by(1)
      end

      it "handles username with whitespace" do
        expect do
          post organization_invite_path(organization.id), params: { username: "  #{invited_user.username}  " }
        end.to change(OrganizationMembership, :count).by(1)
      end
    end

    context "when organization is fully trusted" do
      before do
        organization.update(fully_trusted: true)
      end

      it "creates an active membership (not pending)" do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.to change(OrganizationMembership, :count).by(1)

        membership = OrganizationMembership.last
        expect(membership.user).to eq(invited_user)
        expect(membership.organization).to eq(organization)
        expect(membership.type_of_user).to eq("member")
        expect(membership.invitation_token).to be_nil
      end

      it "sends a notification email and does not send an invitation email", :aggregate_failures do
        allow(OrganizationInvitationMailer).to receive(:with)
        mail_double = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
        mailer = Struct.new(:member_added_email).new(mail_double)
        allow(OrganizationMembershipNotificationMailer).to receive(:with).and_return(mailer)

        post organization_invite_path(organization.id), params: { username: invited_user.username }

        expect(OrganizationMembershipNotificationMailer).to have_received(:with).with(membership_id: kind_of(Integer))
        expect(mail_double).to have_received(:deliver_now)
        expect(OrganizationInvitationMailer).not_to have_received(:with)
      end

      it "redirects with success message" do
        post organization_invite_path(organization.id), params: { username: invited_user.username }
        expect(response).to redirect_to(organization_settings_path(organization.slug, anchor: "section-invitations"))
        expect(flash[:settings_notice]).to include("Successfully added")
      end
    end

    context "when user is not found" do
      it "redirects with error message" do
        post organization_invite_path(organization.id), params: { username: "nonexistent" }
        expect(response).to redirect_to(organization_settings_path(organization.slug, anchor: "section-invitations"))
        expect(flash[:error]).to include("not found")
      end
    end

    context "when user is already a member" do
      before do
        create(:organization_membership, user: invited_user, organization: organization, type_of_user: "member")
      end

      it "does not create a new membership" do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.not_to change(OrganizationMembership, :count)
      end

      it "redirects with error message" do
        post organization_invite_path(organization.id), params: { username: invited_user.username }
        expect(flash[:error]).to include("already a member")
      end
    end

    context "when user already has a pending invitation" do
      before do
        create(:organization_membership, user: invited_user, organization: organization, type_of_user: "pending")
      end

      it "does not create a new membership" do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.not_to change(OrganizationMembership, :count)
      end

      it "redirects with error message" do
        post organization_invite_path(organization.id), params: { username: invited_user.username }
        expect(flash[:error]).to include("already has a pending invitation")
      end
    end

    context "when user is not authorized" do
      let(:regular_user) { create(:user) }

      before do
        sign_in regular_user
      end

      it "raises authorization error" do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when daily invitation rate limit is reached" do
      before do
        seed_pending_invitations(3, base_time: Time.zone.now.beginning_of_day)
      end

      it "does not create a new membership and redirects with rate limit error message", :aggregate_failures do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.not_to change(OrganizationMembership, :count)

        expect(response).to redirect_to(organization_settings_path(organization.slug, anchor: "section-invitations"))
        expect(flash[:error]).to include("daily invitation limit")
        expect(flash[:error]).to include("3")
      end
    end

    context "when total outstanding invitations limit is reached" do
      before do
        seed_pending_invitations(2, base_time: Time.zone.now.beginning_of_day)
        seed_pending_invitations(8, base_time: 2.days.ago, step: 1.hour)
      end

      it "does not create a new membership and redirects with max outstanding error message", :aggregate_failures do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.not_to change(OrganizationMembership, :count)

        expect(response).to redirect_to(organization_settings_path(organization.slug, anchor: "section-invitations"))
        expect(flash[:error]).to include("maximum outstanding invitations")
        expect(flash[:error]).to include("10")
      end
    end

    context "when daily limit is not reached but total outstanding limit is" do
      before do
        seed_pending_invitations(10, base_time: 2.days.ago, step: 1.hour)
      end

      it "checks outstanding limit and redirects with max outstanding error message", :aggregate_failures do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.not_to change(OrganizationMembership, :count)

        expect(response).to redirect_to(organization_settings_path(organization.slug, anchor: "section-invitations"))
        expect(flash[:error]).to include("maximum outstanding invitations")
        expect(flash[:error]).not_to include("daily invitation limit")
      end
    end

    context "when both limits are checked and daily limit is reached first" do
      before do
        seed_pending_invitations(3, base_time: Time.zone.now.beginning_of_day)
      end

      it "checks daily limit first and redirects with daily limit error message", :aggregate_failures do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.not_to change(OrganizationMembership, :count)

        expect(response).to redirect_to(organization_settings_path(organization.slug, anchor: "section-invitations"))
        expect(flash[:error]).to include("daily invitation limit")
      end
    end

    context "when fully trusted organization bypasses rate limits" do
      before do
        organization.update(fully_trusted: true)
        seed_pending_invitations(5, base_time: Time.zone.now.beginning_of_day)
        seed_pending_invitations(5, base_time: 2.days.ago, step: 1.hour)
      end

      it "creates a membership and redirects with success message", :aggregate_failures do
        expect do
          post organization_invite_path(organization.id), params: { username: invited_user.username }
        end.to change(OrganizationMembership, :count).by(1)

        expect(response).to redirect_to(organization_settings_path(organization.slug, anchor: "section-invitations"))
        expect(flash[:error]).to be_nil
        expect(flash[:settings_notice]).to include("Successfully added")
      end
    end
  end

  describe "GET /organizations/confirm_invitation/:token" do
    let(:pending_membership) do
      create(:organization_membership, user: invited_user, organization: organization, type_of_user: "pending")
    end

    context "when user is signed in" do
      before do
        sign_in invited_user
      end

      it "renders the confirmation page" do
        get organization_confirm_invitation_path(token: pending_membership.invitation_token)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(organization.name)
      end

      it "shows error for invalid token" do
        get organization_confirm_invitation_path(token: "invalid-token")
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to include("Invalid")
      end

      it "shows error for already confirmed membership" do
        pending_membership.update(type_of_user: "member")
        get organization_confirm_invitation_path(token: pending_membership.invitation_token)
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to include("already been confirmed")
      end

      it "shows error when signed in as different user" do
        other_user = create(:user)
        sign_in other_user
        get organization_confirm_invitation_path(token: pending_membership.invitation_token)
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to include("invited user")
      end
    end

    context "when user is not signed in" do
      before do
        sign_out :user
      end

      it "renders the confirmation page with sign in prompt" do
        get organization_confirm_invitation_path(token: pending_membership.invitation_token)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Sign In")
      end
    end
  end

  describe "POST /organizations/confirm_invitation/:token" do
    let(:pending_membership) do
      create(:organization_membership, user: invited_user, organization: organization, type_of_user: "pending")
    end

    before do
      sign_in invited_user
    end

    it "confirms the membership" do
      expect do
        post organization_confirm_invitation_path(token: pending_membership.invitation_token)
      end.to change { pending_membership.reload.type_of_user }.from("pending").to("member")
    end

    it "redirects to organization settings" do
      post organization_confirm_invitation_path(token: pending_membership.invitation_token)
      expect(response).to redirect_to(user_settings_path(:organization))
      expect(flash[:settings_notice]).to include("Successfully joined")
    end

    it "does not confirm if token is invalid" do
      expect do
        post organization_confirm_invitation_path(token: "invalid-token")
      end.not_to change { pending_membership.reload.type_of_user }
    end

    it "does not confirm if already confirmed" do
      pending_membership.update(type_of_user: "member")
      expect do
        post organization_confirm_invitation_path(token: pending_membership.invitation_token)
      end.not_to change { pending_membership.reload.type_of_user }
    end
  end
end
