require "rails_helper"

RSpec.describe "SocialPreviews", type: :request do
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }
  let(:organization) { create(:organization) }
  let(:article) { create(:article, user_id: user.id) }

  describe "GET /social_previews/article/:id" do
    it "renders proper article title" do
      get "/social_previews/article/#{article.id}"
      expect(response.body).to include CGI.escapeHTML(article.title)
    end
  end

  describe "GET /social_previews/user/:id" do
    it "renders proper user name" do
      get "/social_previews/user/#{user.id}"
      expect(response.body).to include CGI.escapeHTML(user.name)
    end
  end

  describe "GET /social_previews/user/:id" do
    it "renders proper organization name" do
      get "/social_previews/organization/#{organization.id}"
      expect(response.body).to include CGI.escapeHTML(organization.name)
    end
  end

  describe "GET /social_previews/user/:id" do
    it "renders proper tag name" do
      get "/social_previews/tag/#{tag.id}"
      expect(response.body).to include CGI.escapeHTML(tag.name)
    end
  end
end
