require "rails_helper"

RSpec.describe "Api::V0::Videos" do
  let(:user) { create(:user, created_at: 1.month.ago) }

  def create_article(article_params = {})
    article = create(:article, :video, user: user, title: "video-#{SecureRandom.hex(8)}")
    article.update_columns(article_params) if article_params.any?
    article
  end

  describe "GET /api/videos" do
    it "returns only eligible video articles with the correct json representation and surrogate key",
       :aggregate_failures do
      video_article = create_article
      create_article(published: false)
      create(:article, user: user)
      create_article(score: -4)

      get api_videos_path

      expect(response.parsed_body.size).to eq(1)

      response_video = response.parsed_body.first
      expected_keys = %w[
        type_of id path cloudinary_video_url title user_id video video_duration_in_minutes video_source_url user
      ]
      expect(response_video.keys).to match_array(expected_keys)

      %w[id path cloudinary_video_url title user_id video video_duration_in_minutes video_source_url].each do |attr|
        expect(response_video[attr]).to eq(video_article.public_send(attr))
      end

      expect(response_video["user"]["name"]).to eq(video_article.user.name)

      expected_key = ["videos", "articles", video_article.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end

    it "orders video articles by descending hotness score" do
      video_article = create_article(hotness_score: 10)
      other_video_article = create_article(hotness_score: 9)

      get api_videos_path

      expected_result = [video_article.id, other_video_article.id]
      expect(response.parsed_body.pluck("id")).to eq(expected_result)
    end

    it "supports pagination" do
      3.times { create_article }

      get api_videos_path, params: { page: 1, per_page: 2 }
      expect(response.parsed_body.length).to eq(2)

      get api_videos_path, params: { page: 2, per_page: 2 }
      expect(response.parsed_body.length).to eq(1)
    end

    it "respects API_PER_PAGE_MAX limit set in ENV variable" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(2)

      3.times { create_article }

      get api_videos_path, params: { per_page: 10 }
      expect(response.parsed_body.count).to eq(2)
    end
  end
end
