require "rails_helper"

RSpec.describe "VideoPlayerShow", type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:video_article) { create(:article, user: user) }

  describe "GET /:slug (video articles)" do
    before do
      video_article.update_columns(video: "video", video_source_url: "video", title: "A Video")
      get video_article.path
    end

    it "returns a 200 status when navigating to the video article's page" do
      expect(response).to have_http_status(:success)
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

    it "renders the proper modified at date" do
      time_now = Time.current
      video_article.edited_at = time_now
      expect(response.body).to include CGI.escapeHTML(video_article.readable_edit_date)
    end

    it "renders the proper author" do
      expect(response.body).to include CGI.escapeHTML(video_article.cached_user_username)
    end
  end
end
