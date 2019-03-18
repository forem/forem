require "rails_helper"

RSpec.describe "SocialPreviews", type: :request do
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }
  let(:organization) { create(:organization) }
  let(:article) { create(:article, user_id: user.id) }
  let(:image_url) { "https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1" }

  before do
    stub_request(:post, /hcti.io/).
      to_return(status: 200,
                body: "{ \"url\": \"#{image_url}\" }",
                headers: { "Content-Type" => "application/json" })
  end

  describe "GET /social_previews/article/:id" do
    it "renders proper article title" do
      get "/social_previews/article/#{article.id}"
      expect(response.body).to include CGI.escapeHTML(article.title)
    end

    it "renders shecoded template when tagged with shecoded" do
      she_coded_article = create(:article, tags: "shecoded")

      get "/social_previews/article/#{she_coded_article.id}"

      expect(response).to render_template(:shecoded)
      expect(response.body).to include CGI.escapeHTML(she_coded_article.title)
    end

    it "renders an image when requested and redirects to image url" do
      get "/social_previews/article/#{article.id}.png"

      expect(response).to redirect_to(image_url)
    end
  end

  describe "GET /social_previews/user/:id" do
    it "renders proper user name" do
      get "/social_previews/user/#{user.id}"
      expect(response.body).to include CGI.escapeHTML(user.name)
    end

    it "renders an image when requested and redirects to image url" do
      get "/social_previews/user/#{user.id}.png"

      expect(response).to redirect_to(image_url)
    end
  end

  describe "GET /social_previews/organization/:id" do
    it "renders proper organization name" do
      get "/social_previews/organization/#{organization.id}"
      expect(response.body).to include CGI.escapeHTML(organization.name)
    end

    it "renders an image when requested and redirects to image url" do
      get "/social_previews/organization/#{organization.id}.png"

      expect(response).to redirect_to(image_url)
    end
  end

  describe "GET /social_previews/tag/:id" do
    it "renders proper tag name" do
      get "/social_previews/tag/#{tag.id}"
      expect(response.body).to include CGI.escapeHTML(tag.name)
    end

    it "renders an image when requested and redirects to image url" do
      get "/social_previews/tag/#{tag.id}.png"

      expect(response).to redirect_to(image_url)
    end
  end
end
