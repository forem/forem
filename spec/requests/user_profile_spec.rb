require "rails_helper"

RSpec.describe "UserProfiles", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  describe "GET /user" do
    it "renders to appropriate page" do
      get "/#{user.username}"
      expect(response.body).to include CGI.escapeHTML(user.name)
    end

    it "renders profile page of user after changed username" do
      old_username = user.username
      user.update(username: "new_username_yo_#{rand(10000)}")
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    it "renders profile page of user after two changed usernames" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10000)}")
      user.update(username: "new_new_username_#{rand(10000)}")
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    it "renders organization page if org" do
      get organization.path
      expect(response.body).to include CGI.escapeHTML(organization.name)
    end
  end

  describe "GET /user" do
    it "renders to appropriate page" do
      user = create(:user)
      get "/#{user.username}"
      expect(response.body).to include CGI.escapeHTML(user.name)
    end
  end

  describe "redirect to moderation" do
    it "redirects to admin" do
      user = create(:user)
      get "/#{user.username}/admin"
      expect(response.body).to redirect_to "/admin/users/#{user.id}/edit"
    end

    it "redirects to moderate" do
      user = create(:user)
      get "/#{user.username}/moderate"
      expect(response.body).to redirect_to "/internal/users/#{user.id}/edit"
    end
  end
end
