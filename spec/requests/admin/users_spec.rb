require "rails_helper"

RSpec.describe "admin/users", type: :request do
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
      get "/admin/users"
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /admin/users/:id" do
    it "renders to appropriate page" do
      get "/admin/users/#{user.id}"
      expect(response.body).to include(user.username)
    end

    context "when a user is unregistered" do
      it "renders a message stating that the user isn't registered" do
        user.update_columns(registered: false)
        get "/admin/users/#{user.id}"
        expect(response.body).to include("@#{user.username} has not accepted their invitation yet.")
      end

      it "only displays limited information about the user" do
        user.update_columns(registered: false)
        get "/admin/users/#{user.id}"
        expect(response.body).not_to include("Current Roles")
      end
    end

    context "when a user is registered" do
      it "renders the Admin User profile as expected" do
        get "/admin/users/#{user.id}"
        expect(response.body).to include("Current Roles")
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
      expect(response).to redirect_to("/admin/users/#{user.id}")
    end

    it "shows banish button for new users" do
      get "/admin/users/#{user.id}/edit"
      expect(response.body).to include("Banish User for Spam!")
    end

    it "does not show banish button for non-admins" do
      sign_out(admin)
      expect { get "/admin/users/#{user.id}/edit" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "displays the 'Recent Reactions' section" do
      get "/admin/users/#{user.id}/edit"
      expect(response.body).to include("Recent Reactions")
    end

    it "displays a message when there are no related vomit reactions for a user" do
      get "/admin/users/#{user.id}/edit"
      expect(response.body).to include("Nothing negative to see here! 👀")
    end

    it "displays a list of recent related vomit reactions for a user if any exist" do
      vomit = build(:reaction, category: "vomit", user_id: user.id, reactable_type: "Article", status: "valid")
      get "/admin/users/#{user.id}/edit"
      expect(response.body).to include(vomit.reactable_type)
    end

    it "displays the 'Recent Reports' section" do
      get "/admin/users/#{user.id}/edit"
      expect(response.body).to include("Recent Reports")
    end

    it "displays a message when there are no related reports for a user" do
      get "/admin/users/#{user.id}/edit"
      expect(response.body).to include("Nothing to report here! 👀")
    end

    it "displays a list of recent reports for a user if any exist" do
      report = build(:feedback_message, category: "spam", affected_id: user.id, feedback_type: "spam", status: "Open")
      get "/admin/users/#{user.id}/edit"
      expect(response.body).to include(report.feedback_type)
    end
  end

  describe "POST /admin/users/:id/banish" do
    it "bans user for spam" do
      allow(Moderator::BanishUserWorker).to receive(:perform_async)
      post "/admin/users/#{user.id}/banish"
      expect(Moderator::BanishUserWorker).to have_received(:perform_async).with(admin.id, user.id)
      expect(request.flash[:success]).to include("This user is being banished in the background")
    end
  end

  describe "POST admin/users/:id/verify_email_ownership" do
    it "allows a user to verify email ownership" do
      post "/admin/users/#{user.id}/verify_email_ownership", params: { user_id: user.id }

      path = verify_email_authorizations_path(
        confirmation_token: user.email_authorizations.first.confirmation_token,
        username: user.username,
      )
      verification_link = app_url(path)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.count).to eq(1)
      expect(deliveries.first.subject).to eq("Verify Your #{SiteConfig.community_name} Account Ownership")
      expect(deliveries.first.text_part.body).to include(verification_link)

      sign_in(user)
      get verification_link
      expect(user.email_authorizations.last.verified_at).to be_within(1.minute).of Time.now.utc

      ActionMailer::Base.deliveries.clear
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
      allow(SiteConfig).to receive(:authentication_providers).and_return(Authentication::Providers.available)
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

  describe "POST admin/users/:id/export_data" do
    it "redirects properly to the user edit page" do
      sign_in admin
      post export_data_admin_user_path(user), params: { send_to_admin: "true" }
      expect(response).to redirect_to edit_admin_user_path(user)
    end
  end
end
