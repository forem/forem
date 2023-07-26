require "rails_helper"

RSpec.describe "Billboards" do
  let(:user)    { create(:user) }
  let(:article) { create(:article, user: user) }

  let(:max_age) { 15.minutes.to_i }
  let(:stale_if_error) { 26_400 }

  describe "GET /:username/:slug/billboards/:placement_area" do
    before do
      create(:display_ad, placement_area: "post_comments", published: true, approved: true)
    end

    it "returns the correct response" do
      get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
      display_ad = DisplayAd.find_by(placement_area: "post_comments")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(display_ad.processed_html)
    end

    context "when signed in" do
      before do
        sign_in user
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
      end

      it "does not set surrogate key headers" do
        expect(response.headers["Surrogate-key"]).to be_nil
      end

      it "does not set x-accel-expires headers" do
        expect(response.headers["x-accel-expires"]).to be_nil
      end

      it "does not set Fastly cache control and surrogate control headers" do
        expect(response.headers.to_hash).not_to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end

    context "when signed out" do
      before do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
      end

      it "sets the surrogate key header equal to params for article" do
        display_ad = DisplayAd.find_by(placement_area: "post_comments")
        expect(response.headers["Surrogate-Key"]).to eq("display_ads/#{display_ad.id}")
      end

      it "sets the x-accel-expires header equal to max-age for article" do
        expect(response.headers["X-Accel-Expires"]).to eq(max_age.to_s)
      end

      it "sets Fastly cache control and surrogate control headers" do
        expect(response.headers.to_hash).to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end
  end
end
