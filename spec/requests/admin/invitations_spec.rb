require "rails_helper"

RSpec.describe "/admin/member_manager/invitations" do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
    allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
  end

  describe "GET /admin/member_manager/invitations" do
    it "renders to appropriate page" do
      user.update_column(:registered, false)
      get admin_invitations_path
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /admin/member_manager/invitations/new" do
    it "renders to appropriate page" do
      get new_admin_invitation_path
      expect(response.body).to include("Email")
    end
  end

  describe "POST /admin/member_manager/invitations" do
    it "creates new invitation" do
      post admin_invitations_path,
           params: { user: { email: "hey#{rand(1000)}@email.co" } }
      expect(User.last.registered).to be false
    end

    it "enqueues an invitation email to be sent", :aggregate_failures do
      assert_enqueued_with(job: Devise.mailer.delivery_job) do
        post admin_invitations_path,
             params: { user: { email: "hey#{rand(1000)}@email.co" } }
      end

      expect(enqueued_jobs.first[:args]).to match(array_including("invitation_instructions"))
    end

    it "enqueues an invitation email to be sent with custom subject", :aggregate_failures do
      allow(DeviseMailer).to receive(:invitation_instructions).and_call_original

      assert_enqueued_with(job: Devise.mailer.delivery_job) do
        user_params = { email: "hey#{rand(1000)}@email.co",
                        custom_invite_subject: "Custom Subject!",
                        custom_invite_message: "**Custom message**",
                        custom_invite_footnote: "Custom footnote" }
        post admin_invitations_path, params: { user: user_params }
      end

      expect(DeviseMailer).to have_received(:invitation_instructions) do |_user, _token, args|
        expect(args).to include(
          custom_invite_subject: "Custom Subject!",
          custom_invite_message: "**Custom message**",
        )
      end
      expect(enqueued_jobs.first[:args]).to match(array_including("invitation_instructions"))
    end

    it "does not create an invitation if a user with that email exists" do
      expect do
        post admin_invitations_path,
             params: { user: { email: admin.email } }
      end.not_to change(User, :count)
      expect(admin.reload.registered).to be true
      expect(flash[:error].present?).to be true
    end
  end

  describe "POST /admin/member_manager/invitations/:id/resend" do
    let!(:invitation) { create(:user, registered: false) }

    it "enqueues an invitation email to be resent" do
      assert_enqueued_with(job: Devise.mailer.delivery_job) do
        post resend_admin_invitation_path(invitation.id)
      end
      expect(enqueued_jobs.last[:args]).to match(array_including("invitation_instructions"))
    end
  end

  describe "DELETE /admin/member_manager/invitations" do
    let!(:invitation) { create(:user, registered: false) }

    before do
      sign_in admin
    end

    it "deletes the invitation" do
      expect do
        delete admin_invitation_path(invitation.id)
      end.to change(User, :count).by(-1)
      expect(response.body).to redirect_to admin_invitations_path
    end
  end
end
