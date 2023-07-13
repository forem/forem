require "rails_helper"

RSpec.describe "Billboards" do
  let(:user)    { create(:user) }
  let(:article) { create(:article, user: user) }

  let(:max_age) { 15.minutes.to_i }
  let(:stale_if_error) { 26_400 }

  def create_billboard(**options)
    defaults = {
      approved: true,
      published: true,
      display_to: :all
    }
    create(:display_ad, **options.reverse_merge(defaults))
  end

  describe "GET /:username/:slug/billboards/:placement_area" do
    let!(:billboard) { create_billboard(placement_area: "post_comments") }

    it "returns the correct response" do
      get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(billboard.processed_html)
    end

    context "when client geolocation is present" do
      let!(:canada_billboard) { create_billboard(placement_area: "sidebar_left", geo: %w[CA FR]) }
      let!(:us_billboard) { create_billboard(placement_area: "sidebar_left", geo: %w[NL US]) }
      let(:client_in_newfoundland_canada) { { "HTTP_CLIENT_GEO" => "CA-NL" } }
      let(:client_in_california_usa) { { "HTTP_CLIENT_GEO" => "US-CA" } }

      it "returns only billboards targeting their location" do
        # DisplayAd.for_display uses random sampling, so we run this a few times for confidence
        5.times do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_newfoundland_canada

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(canada_billboard.processed_html)
          expect(response.parsed_body).not_to include(us_billboard.processed_html)

          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_california_usa

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(us_billboard.processed_html)
          expect(response.parsed_body).not_to include(canada_billboard.processed_html)
        end
      end
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
        expect(response.headers["Surrogate-Key"]).to eq("display_ads/#{billboard.id}")
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
