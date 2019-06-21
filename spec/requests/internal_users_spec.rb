require "rails_helper"

RSpec.describe "internal/users", type: :request do
  let!(:user) { create(:user) }
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

  describe "GET internal/users/:id/edit" do
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

  describe "PUT internal/users/:id/edit" do
    it "bans user for spam" do
      post "/internal/users/#{user.id}/banish"
      expect(user.reload.username).to include("spam")
    end
  end
end
