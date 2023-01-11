require "rails_helper"

RSpec.describe "VideoPlayerShow" do
  let(:user) { create(:user) }
  let(:video_article) { create(:article, user: user) }

  describe "GET /:slug (video articles)" do
    before do
      video_article.update_columns(video: "video", video_source_url: "video", title: "A Video")
      get video_article.path
    end

    it "returns a 200 status when navigating to the video article's page" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the proper title" do
      expect(response.body).to include CGI.escapeHTML(video_article.title)
    end

    it "renders the proper description" do
      expect(response.body).to include CGI.escapeHTML(video_article.description)
    end

    it "renders the proper video url" do
      expect(response.body).to include CGI.escapeHTML(video_article.video_source_url)
    end

    it "renders the proper published at date" do
      expect(response.body).to include CGI.escapeHTML(video_article.readable_publish_date)
    end

    it "renders the proper author" do
      expect(response.body).to include CGI.escapeHTML(video_article.cached_user_username)
    end
  end
end
