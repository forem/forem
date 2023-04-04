require "rails_helper"

RSpec.describe "DisplayAds" do
  let(:user)    { create(:user) }
  let(:article) { create(:article, user: user) }

  let(:max_age) { 15.minutes.to_i }
  let(:stale_if_error) { 26_400 }

  describe "GET /display_ads/for_display?article_id=:article.id" do
    before do
      create(:display_ad, placement_area: "post_comments", published: true, approved: true)
    end

    context "when signed in" do
      before do
        sign_in user

        get display_ads_for_display_path(article_id: article.id)
      end

      it "does not set surrogate key headers" do
        expect(response.headers["surrogate-key"]).to be_nil
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
      before { get display_ads_for_display_path(article_id: article.id) }

      it "sets the surrogate key header equal to params for article" do
        expect(response.headers["Surrogate-Key"]).to eq(controller.params.to_s)
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
