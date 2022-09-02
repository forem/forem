require "rails_helper"

RSpec.describe "Api::V0::Videos", type: :request do
  let(:user) { create(:user, created_at: 1.month.ago) }

  def create_article(article_params = {})
    default_params = {
      user: user, video: "https://example.com", video_thumbnail_url: "https://example.com", title: "video"
    }
    params = default_params.merge(article_params)
    create(:article, params)
  end

  describe "GET /api/videos" do
    it "returns articles with videos" do
      create_article

      get api_videos_path

      expect(response.parsed_body.size).to eq(1)
    end

    it "does not return unpublished video articles" do
      article = create_article
      article.update(published: false)

      get api_videos_path

      expect(response.parsed_body.size).to eq(1)
    end

    it "does not return regular articles without videos" do
      create(:article)

      get api_videos_path

      expect(response.parsed_body.size).to eq(0)
    end

    it "does not return video articles with a score that is too low" do
      create_article(score: -4)

      get api_videos_path

      expect(response.parsed_body.size).to eq(0)
    end

    it "returns video articles with the correct json representation", :aggregate_failures do
      video_article = create_article

      get api_videos_path

      response_video = response.parsed_body.first
      expected_keys = %w[type_of id path cloudinary_video_url title user_id video_duration_in_minutes video_source_url
                         user]
      expect(response_video.keys).to match_array(expected_keys)

      %w[id path cloudinary_video_url title user_id video_duration_in_minutes video_source_url].each do |attr|
        expect(response_video[attr]).to eq(video_article.public_send(attr))
      end

      expect(response_video["user"]["name"]).to eq(video_article.user.name)
    end

    it "orders video articles by descending hotness score" do
      video_article = create_article(hotness_score: 10)
      other_video_article = create_article(hotness_score: 9)

      get api_videos_path

      expected_result = [video_article.id, other_video_article.id]
      expect(response.parsed_body.map { |a| a["id"] }).to eq(expected_result)
    end

    it "supports pagination" do
      create_list(
        :article, 3,
        user: user, video: "https://example.com", video_thumbnail_url: "https://example.com", title: "video"
      )

      get api_videos_path, params: { page: 1, per_page: 2 }
      expect(response.parsed_body.length).to eq(2)

      get api_videos_path, params: { page: 2, per_page: 2 }
      expect(response.parsed_body.length).to eq(1)
    end

    it "respects API_PER_PAGE_MAX limit set in ENV variable" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(2)

      create_list(
        :article, 3,
        user: user, video: "https://example.com", video_thumbnail_url: "https://example.com", title: "video"
      )

      get api_tags_path, params: { per_page: 10 }
      expect(response.parsed_body.count).to eq(2)
    end

    it "sets the correct edge caching surrogate key for all video articles" do
      video_article = create_article

      get api_videos_path

      expected_key = ["videos", "articles", video_article.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end
end
