require "rails_helper"

RSpec.describe "Videos", type: :request do
  let(:unauthorized_user) { create(:user) }
  let(:authorized_user)   { create(:user, :video_permission) }

  describe "GET /api/videos" do
    it "shows articles with video" do
      not_video_article = create(:article)
      video_article = create(:article)
      video_article.update_columns(video: "video", video_thumbnail_url: "video", title: "this video")
      get "/api/videos"
      expect(response.body).to include(video_article.title)
      expect(response.body).not_to include(not_video_article.title)
    end
  end
end
