require "rails_helper"

RSpec.describe "internal/users", type: :request do
  let!(:user) { create(:user, :with_identity, identities: ["github"]) }
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "GETS /internal/users" do
    it "renders to appropriate page" do
      get "/internal/users"
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /internal/users/:id" do
    it "renders to appropriate page" do
      get "/internal/users/#{user.id}"
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /internal/users/:id/edit" do
    it "redirects from /username/moderate" do
      get "/#{user.username}/moderate"
      expect(response).to redirect_to("/internal/users/#{user.id}")
    end

    it "shows banish button for new users" do
      get "/internal/users/#{user.id}/edit"
      expect(response.body).to include("Banish User for Spam!")
    end

    it "does not show banish button for non-admins" do
      sign_out(admin)
      expect { get "/internal/users/#{user.id}/edit" }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "POST /internal/users/:id/banish" do
    it "bans user for spam" do
      allow(Moderator::BanishUserWorker).to receive(:perform_async)
      post "/internal/users/#{user.id}/banish"
      expect(Moderator::BanishUserWorker).to have_received(:perform_async).with(admin.id, user.id)
      expect(request.flash[:success]).to include("This user is being banished in the background")
    end
  end

  describe "DELETE /internal/users/:id/remove_identity" do
    it "removes the given identity" do
      identity = user.identities.first
      delete "/internal/users/#{user.id}/remove_identity", params: { user: { identity_id: identity.id } }
      expect { identity.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "updates their social account's username to nil" do
      identity = user.identities.first
      delete "/internal/users/#{user.id}/remove_identity", params: { user: { identity_id: identity.id } }
      expect(user.reload.github_username).to eq nil
    end
  end

  describe "POST internal/users/:id/recover_identity" do
    it "recovers a deleted identity" do
      identity = user.identities.first
      backup = BackupData.backup!(identity)
      identity.delete
      post "/internal/users/#{user.id}/recover_identity", params: { user: { backup_data_id: backup.id } }
      expect(identity).to eq Identity.first
    end

    it "deletes the backup data" do
      identity = user.identities.first
      backup = BackupData.backup!(identity)
      identity.delete
      post "/internal/users/#{user.id}/recover_identity", params: { user: { backup_data_id: backup.id } }
      expect { backup.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
