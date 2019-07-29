require "rails_helper"

RSpec.describe "UserProfiles", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  describe "GET /user" do
    it "renders to appropriate page" do
      get "/#{user.username}"
      expect(response.body).to include CGI.escapeHTML(user.name)
    end

    it "renders pins if any" do
      create(:article, user_id: user.id)
      create(:article, user_id: user.id)
      last_article = create(:article, user_id: user.id)
      create(:profile_pin, pinnable_id: last_article.id, profile_id: user.id)
      get "/#{user.username}"
      expect(response.body).to include "Pinned"
    end

    it "does not render pins if they don't exist" do
      get "/#{user.username}"
      expect(response.body).not_to include "Pinned"
    end

    it "renders profile page of user after changed username" do
      old_username = user.username
      user.update(username: "new_username_yo_#{rand(10_000)}")
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    it "renders profile page of user after two changed usernames" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10_000)}")
      user.update(username: "new_new_username_#{rand(10_000)}")
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    context "when organization" do
      it "renders organization page if org" do
        get organization.path
        expect(response.body).to include CGI.escapeHTML(organization.name)
      end

      it "renders organization users on sidebar" do
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        get organization.path
        expect(response.body).to include user.profile_image_url
      end

      it "renders no sponsors if not sponsor" do
        get organization.path
        expect(response.body).not_to include "Gold Community Sponsor"
      end

      it "renders sponsor if it is sponsored" do
        create(:sponsorship, level: :gold, status: :live, organization: organization)
        get organization.path
        expect(response.body).to include "Gold Community Sponsor"
      end
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
      expect(response.body).to redirect_to "/internal/users/#{user.id}"
    end
  end
end
