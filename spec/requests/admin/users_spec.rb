require "rails_helper"

RSpec.describe "/admin/users", type: :request do
  let!(:user) do
    omniauth_mock_github_payload
    create(:user, :with_identity, identities: ["github"])
  end
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "GET /admin/users" do
    it "renders to appropriate page" do
      get admin_users_path
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /admin/users/:id" do
    it "renders to appropriate page", :aggregate_failures do
      get admin_user_path(user)

      expect(response.body).to include(user.username)
      expect(response.body).not_to include("Go back to All members")
    end

    it "renders the new admin page if the feature flag is enabled" do
      FeatureFlag.enable(:new_admin_members, admin)

      get admin_user_path(user)

      expect(response.body).to include("Go back to All members")
    end

    context "when a user is unregistered" do
      it "renders a message stating that the user isn't registered" do
        user.update_columns(registered: false)
        get admin_user_path(user.id)
        expect(response.body).to include("@#{user.username} has not accepted their invitation yet.")
      end

      it "only displays limited information about the user" do
        user.update_columns(registered: false)
        get admin_user_path(user.id)
        expect(response.body).not_to include("Activity")
      end
    end

    context "when a user is registered" do
      it "renders the Admin User profile as expected" do
        get admin_user_path(user.id)
        expect(response.body).to include("Activity")
      end
    end

    context "when a user has been sent an email" do
      it "renders a link to the user email preview" do
        email = create(:email_message, user: user, to: user.email)
        get admin_user_path(user.id)

        preview_path = admin_user_email_message_path(user, email)
        expect(response.body).to include(preview_path)
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    it "redirects from /username/moderate" do
      get "/#{user.username}/moderate"
      expect(response).to redirect_to(admin_user_path(user.id))
    end

    it "shows banish button for new users" do
      get edit_admin_user_path(user.id)
      expect(response.body).to include("Banish User for Spam!")
    end

    it "does not show banish button for non-admins" do
      sign_out(admin)
      expect { get edit_admin_user_path(user.id) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "displays the 'Current Roles' section" do
      get edit_admin_user_path(user.id)
      expect(response.body).to include("Current Roles")
    end

    it "displays the 'Recent Reactions' section" do
      get edit_admin_user_path(user.id)
      expect(response.body).to include("Recent Reactions")
    end

    it "displays a message when there are no related vomit reactions for a user" do
      get edit_admin_user_path(user.id)
      expect(response.body).to include("Nothing negative to see here! 👀")
    end

    it "displays a list of recent related vomit reactions for a user if any exist" do
      vomit = build(:reaction, category: "vomit", user_id: user.id, reactable_type: "Article", status: "valid")
      get edit_admin_user_path(user.id)
      expect(response.body).to include(vomit.reactable_type)
    end

    it "displays the 'Recent Reports' section" do
      get edit_admin_user_path(user.id)
      expect(response.body).to include("Recent Reports")
    end

    it "displays a message when there are no related reports for a user" do
      get edit_admin_user_path(user.id)
      expect(response.body).to include("Nothing to report here! 👀")
    end

    it "displays a list of recent reports for a user if any exist" do
      report = build(:feedback_message, category: "spam", affected_id: user.id, feedback_type: "spam", status: "Open")
      get edit_admin_user_path(user.id)
      expect(response.body).to include(report.feedback_type)
    end
  end

  describe "POST /admin/users/:id/banish" do
    it "bans user for spam" do
      allow(Moderator::BanishUserWorker).to receive(:perform_async)
      post banish_admin_user_path(user.id)
      expect(Moderator::BanishUserWorker).to have_received(:perform_async).with(admin.id, user.id)
      expect(request.flash[:success]).to include("This user is being banished in the background")
    end
  end

  describe "POST /admin/users/:id/send_email" do
    let(:params) do
      {
        email_body: "Body",
        email_subject: "subject",
        user_id: user.id.to_s
      }
    end
    let(:mailer) { double }
    let(:message_delivery) { double }

    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    end

    context "when interacting via a browser" do
      it "returns not found for non existing users" do
        expect { post send_email_admin_user_path(9999), params: params }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the email if an error occurs", :aggregate_failures do
        allow(NotifyMailer).to receive(:with).with(params).and_return(mailer)
        allow(mailer).to receive(:user_contact_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now).and_return(false)

        assert_no_emails do
          post send_email_admin_user_path(user.id), params: params
        end

        expect(response).to redirect_to(admin_users_path)
        expect(flash[:danger]).to include("failed")
      end

      it "sends an email to the user", :aggregate_failures do
        assert_emails(1) do
          post send_email_admin_user_path(user.id), params: params
        end

        expect(response).to redirect_to(admin_users_path)
        expect(flash[:success]).to include("sent")

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq(params[:email_subject])
        expect(email.text_part.body).to include(params[:email_body])
      end
    end

    context "when interacting via ajax" do
      it "returns not found for non existing users" do
        expect do
          post send_email_admin_user_path(9999), params: params, xhr: true
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the email if an error occurs", :aggregate_failures do
        allow(NotifyMailer).to receive(:with).with(params).and_return(mailer)
        allow(mailer).to receive(:user_contact_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now).and_return(false)

        assert_no_emails do
          post send_email_admin_user_path(user.id), params: params, xhr: true
        end

        expect(response).to have_http_status(:service_unavailable)
        expect(response.parsed_body["error"]).to include("failed")
      end

      it "sends an email to the user", :aggregate_failures do
        assert_emails(1) do
          post send_email_admin_user_path(user.id), params: params, xhr: true
        end

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to include("sent")

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq(params[:email_subject])
        expect(email.text_part.body).to include(params[:email_body])
      end
    end
  end

  describe "POST /admin/users/:id/verify_email_ownership" do
    let(:mailer) { double }
    let(:message_delivery) { double }

    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    end

    context "when interacting via a browser" do
      it "returns not found for non existing users" do
        expect do
          post verify_email_ownership_admin_user_path(9999), params: { user_id: user.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the email if an error occurs", :aggregate_failures do
        allow(VerificationMailer).to receive(:with).with(user_id: user.id.to_s).and_return(mailer)
        allow(mailer).to receive(:account_ownership_verification_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now).and_return(false)

        assert_no_emails do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }
        end

        expect(response).to redirect_to(admin_users_path)
        expect(flash[:danger]).to include("failed")
      end

      it "sends an email", :aggregate_failures do
        assert_emails(1) do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }
        end

        expect(response).to redirect_to(admin_users_path)
        expect(flash[:success]).to include("sent")
      end

      it "allows a user to verify email ownership", :aggregate_failures do
        post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }

        path = verify_email_authorizations_path(
          confirmation_token: user.email_authorizations.first.confirmation_token,
          username: user.username,
        )
        verification_link = app_url(path)

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq("Verify Your #{Settings::Community.community_name} Account Ownership")
        expect(email.text_part.body).to include(verification_link)

        sign_in(user)
        get verification_link
        expect(user.email_authorizations.last.verified_at)
          .to be_within(1.minute)
          .of Time.current
      end
    end

    context "when interacting via ajax" do
      it "returns not found for non existing users" do
        expect do
          post verify_email_ownership_admin_user_path(9999), params: { user_id: user.id }, xhr: true
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the email if an error occurs", :aggregate_failures do
        allow(VerificationMailer).to receive(:with).with(user_id: user.id.to_s).and_return(mailer)
        allow(mailer).to receive(:account_ownership_verification_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now).and_return(false)

        assert_no_emails do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }, xhr: true
        end

        expect(response).to have_http_status(:service_unavailable)
        expect(response.parsed_body["error"]).to include("failed")
      end

      it "sends an email", :aggregate_failures do
        assert_emails(1) do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }, xhr: true
        end

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to include("sent")
      end

      it "allows a user to verify email ownership", :aggregate_failures do
        post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }, xhr: true

        path = verify_email_authorizations_path(
          confirmation_token: user.email_authorizations.first.confirmation_token,
          username: user.username,
        )
        verification_link = app_url(path)

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq("Verify Your #{Settings::Community.community_name} Account Ownership")
        expect(email.text_part.body).to include(verification_link)

        sign_in(user)
        get verification_link
        expect(user.email_authorizations.last.verified_at)
          .to be_within(1.minute)
          .of Time.current
      end
    end
  end

  describe "DELETE /admin/users/:id/remove_identity" do
    let(:provider) { Authentication::Providers.available.first }
    let(:user) do
      omniauth_mock_providers_payload
      create(:user, :with_identity)
    end

    before do
      omniauth_mock_providers_payload
      allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    end

    it "removes the given identity" do
      identity = user.identities.first

      delete remove_identity_admin_user_path(user.id), params: { user: { identity_id: identity.id } }

      expect { identity.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "updates their social account's username to nil" do
      identity = user.identities.first

      delete remove_identity_admin_user_path(user.id), params: { user: { identity_id: identity.id } }

      expect(user.public_send("#{identity.provider}_username")).to be(nil)
    end

    it "does not remove GitHub repositories if the removed identity is not GitHub" do
      create(:github_repo, user: user)

      identity = user.identities.twitter.first

      expect do
        delete remove_identity_admin_user_path(user.id), params: { user: { identity_id: identity.id } }
      end.not_to change(user.github_repos, :count)
    end

    it "removes GitHub repositories if the removed identity is GitHub" do
      repo = create(:github_repo, user: user)

      identity = user.identities.github.first

      expect do
        delete remove_identity_admin_user_path(user.id), params: { user: { identity_id: identity.id } }
      end.to change(user.github_repos, :count).by(-1)

      expect(GithubRepo.exists?(id: repo.id)).to be(false)
    end
  end

  describe "PATCH admin/users/:id/unlock_access" do
    it "unlocks a locked user account" do
      user.lock_access!
      expect do
        patch unlock_access_admin_user_path(user)
      end.to change { user.reload.access_locked? }.from(true).to(false)
    end
  end

  describe "POST /admin/users/:id/export_data" do
    it "redirects properly to the user edit page" do
      sign_in admin
      post export_data_admin_user_path(user), params: { send_to_admin: "true" }
      expect(response).to redirect_to edit_admin_user_path(user)
    end
  end
end
