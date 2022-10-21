require "rails_helper"

RSpec.describe "SocialPreviews", type: :request do
  let(:user) { create(:user) }
  let(:tag) { create(:tag, badge: create(:badge)) }
  let(:organization) { create(:organization) }
  let(:article) { create(:article, user_id: user.id, tags: tag.name) }
  let(:comment) { create(:comment, user_id: user.id, commentable: article) }
  let(:image_url) { "https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1" }

  before do
    stub_request(:post, /hcti.io/)
      .to_return(status: 200,
                 body: "{ \"url\": \"#{image_url}\" }",
                 headers: { "Content-Type" => "application/json" })
  end

  describe "GET /social_previews/article/:id" do
    it "renders proper article title" do
      get "/social_previews/article/#{article.id}"
      expect(response.body).to include CGI.escapeHTML(article.title)
    end

    it "renders consistent HTML between requests" do
      # We use the HTML for caching. It needs to be deterministic (if data is unchanged, the HTML should be the same)
      get "/social_previews/article/#{article.id}"
      first_request_body = response.body

      get "/social_previews/article/#{article.id}"
      second_request_body = response.body

      expect(first_request_body).to eq second_request_body
    end

    it "renders an image when requested and redirects to image url" do
      get "/social_previews/article/#{article.id}.png"

      expect(response).to redirect_to(image_url)
    end
  end
end
