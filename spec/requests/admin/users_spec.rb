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

  describe "GETS /admin/users" do
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
    it "removes the given identity" do
      identity = user.identities.first
      delete "/admin/users/#{user.id}/remove_identity", params: { user: { identity_id: identity.id } }
      expect { identity.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "updates their social account's username to nil" do
      identity = user.identities.first
      delete "/admin/users/#{user.id}/remove_identity", params: { user: { identity_id: identity.id } }
      expect(user.reload.github_username).to eq nil
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
end
