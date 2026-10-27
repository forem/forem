require "rails_helper"

RSpec.describe "VideoPlayerShow" do
  let(:user) { create(:user) }
  let(:video_article) { create(:article, user: user) }

  describe "GET /:slug (video articles)" do
    before do
      video_article.update_columns(video: "video", video_source_url: "video", title: "A Video")
      get video_article.path
    end

    it "renders the video article page with title, description, video url, date, and author", :aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include CGI.escapeHTML(video_article.title)
      expect(response.body).to include CGI.escapeHTML(video_article.description)
      expect(response.body).to include CGI.escapeHTML(video_article.video_source_url)
      expect(response.body).to include CGI.escapeHTML(video_article.readable_publish_date)
      expect(response.body).to include CGI.escapeHTML(video_article.cached_user_username)
    end
  end
end
