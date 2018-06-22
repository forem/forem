require "rails_helper"

RSpec.describe "SocialPreviews", type: :request do

  before do
    @user = create(:user)
    @tag = create(:tag)
    @organization = create(:organization)
    @article = create(:article, user_id: @user.id)
  end

  describe "GET /social_previews/article/:id" do
    it "renders proper article title" do
      get "/social_previews/article/#{@article.id}"
      expect(response.body).to include CGI.escapeHTML(@article.title)
    end
  end
  describe "GET /social_previews/user/:id" do
    it "renders proper user name" do
      get "/social_previews/user/#{@user.id}"
      expect(response.body).to include CGI.escapeHTML(@user.name)
    end
  end
  describe "GET /social_previews/user/:id" do
    it "renders proper organization name" do
      get "/social_previews/organization/#{@organization.id}"
      expect(response.body).to include CGI.escapeHTML(@organization.name)
    end
  end
  describe "GET /social_previews/user/:id" do
    it "renders proper tag name" do
      get "/social_previews/tag/#{@tag.id}"
      expect(response.body).to include CGI.escapeHTML(@tag.name)
    end
  end
end
