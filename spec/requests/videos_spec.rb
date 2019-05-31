require "rails_helper"

RSpec.describe "Videos", type: :request do
  let(:unauthorized_user) { create(:user) }
  let(:authorized_user)   { create(:user, :video_permission) }

  describe "GET /videos" do
    it "shows video page" do
      get "/videos"
      expect(response.body).to include "DEV on Video"
    end

    it "shows articles with video" do
      not_video_article = create(:article)
      video_article = create(:article)
      video_article.update_columns(video: "video", video_thumbnail_url: "video", title: "this video")
      get "/videos"
      expect(response.body).to include video_article.title
      expect(response.body).not_to include not_video_article.title
    end
  end

  describe "GET /videos/new" do
    context "when not authorized" do
      it "redirects non-logged in users" do
        expect { get "/videos/new" }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "redirects logged in users" do
        sign_in unauthorized_user
        expect { get "/videos/new" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when authorized" do
      it "allows authorized users" do
        sign_in authorized_user
        get "/videos/new"
        expect(response.body).to include "Upload Video File"
      end
    end
  end

  describe "POST /videos" do
    context "when not authorized" do
      it "redirects non-logged in users" do
        expect { post "/videos" }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "redirects logged in users" do
        sign_in unauthorized_user
        expect { post "/videos" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when authorized" do
      before do
        sign_in authorized_user
      end

      it "redirects to the article's edit page for the logged in user" do
        stub_request(:get, /dw71fyauz7yz9\.cloudfront\.net\//).to_return(status: 200, body: "", headers: {})
        post "/videos", params: { article: { video: "https://www.something.com/something.mp4" } }
        expect(response.status).to eq(302)
      end
    end
  end
end
