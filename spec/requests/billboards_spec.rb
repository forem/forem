require "rails_helper"

RSpec.describe "Billboards" do
  let(:user)    { create(:user) }
  let(:article) { create(:article, user: user) }

  let(:max_age) { 3.minutes.to_i }
  let(:stale_if_error) { 26_400 }

  def create_billboard(**options)
    defaults = {
      approved: true,
      published: true,
      display_to: :all,
      color: "#FF5733"
    }
    create(:billboard, **options.reverse_merge(defaults))
  end

  describe "GET /:username/:slug/billboards/:placement_area with role-based filtering" do
    before do
      allow(user).to receive(:cached_role_names).and_return(%w[editor moderator])
      sign_in user
    end

    context "when target_role_names includes user's role" do
      let!(:targeted_billboard) { create_billboard(placement_area: "post_comments", target_role_names: ["editor"]) }

      it "includes billboards that target user's role" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(targeted_billboard.processed_html)
      end
    end

    context "when exclude_role_names includes user's role" do
      let!(:excluded_billboard) { create_billboard(placement_area: "post_comments", exclude_role_names: ["moderator"]) }

      it "excludes billboards that should not be shown to user's role" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).not_to include(excluded_billboard.processed_html)
      end
    end

    context "when target_role_names does not include user's role" do
      let!(:non_targeted_billboard) do
        create_billboard(placement_area: "post_comments", target_role_names: ["admin"],
                         body_markdown: rand(10_000).to_s)
      end

      it "excludes billboards that do not target user's role" do
        p non_targeted_billboard.target_role_names
        p user.cached_role_names
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).not_to include(non_targeted_billboard.processed_html)
      end
    end

    context "when exclude_role_names does not include user's role" do
      let!(:non_excluded_billboard) { create_billboard(placement_area: "post_comments", exclude_role_names: ["admin"]) }

      it "includes billboards that are not excluded for user's role" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(non_excluded_billboard.processed_html)
      end
    end

    context "when both target_role_names and exclude_role_names are empty" do
      let!(:open_billboard) { create_billboard(placement_area: "post_comments") }

      it "includes billboards that have no role restrictions" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(open_billboard.processed_html)
      end
    end
  end

  describe "GET /:username/:slug/billboards/:color" do
    context "when placement_area includes 'fixed_'" do
      let!(:billboard) { create_billboard(placement_area: "post_fixed_bottom") }

      it "includes the correct style string" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_fixed_bottom")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("border-top: calc(9px + 0.5vw) solid #{billboard.color}")
      end
    end

    context "when placement_area does not include 'fixed_'" do
      let!(:billboard) { create_billboard(placement_area: "post_comments") }

      it "includes the correct style string" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("border: 5px solid #{billboard.color}")
      end
    end

    context "when color is blank" do
      let!(:billboard) { create_billboard(placement_area: "post_comments", color: "") }

      it "returns an empty style string" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("border-top: calc(9px + 0.5vw) solid")
        expect(response.body).not_to include("border: 5px solid")
      end
    end
  end

  describe "GET /:username/:slug/billboards/:placement_area" do
    let!(:billboard) { create_billboard(placement_area: "post_comments") }

    it "returns the correct response" do
      get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(billboard.processed_html)
    end

    # rubocop:disable RSpec/NestedGroups
    context "when client geolocation is present" do
      let(:client_in_alberta_canada) { { "X-Client-Geo" => "CA-AB", "X-Cacheable-Client-Geo" => "CA" } }
      let(:client_in_california_usa) { { "X-Client-Geo" => "US-CA", "X-Cacheable-Client-Geo" => "US" } }

      let!(:canada_billboard) { create_billboard(placement_area: "sidebar_left", target_geolocations: "CA") }
      let!(:california_billboard) { create_billboard(placement_area: "sidebar_left", target_geolocations: "US-CA") }

      before do
        allow(FeatureFlag).to receive(:enabled?).with(:billboard_location_targeting).and_return(true)
      end

      context "with signed-in user" do
        before do
          sign_in user
        end

        it "returns only billboards targeting their location" do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_alberta_canada

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(canada_billboard.processed_html)
          expect(response.parsed_body).not_to include(california_billboard.processed_html)
        end

        it "is accurate for more precise locations" do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_california_usa

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(california_billboard.processed_html)
          expect(response.parsed_body).not_to include(canada_billboard.processed_html)
        end

        it "does not set Vary header" do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_alberta_canada

          expect(response).to have_http_status(:ok)
          expect(response.headers["Vary"]).not_to include("X-Client-Geo", "X-Cacheable-Client-Geo")
        end
      end

      context "without signed-in user" do
        it "does not return billboards targeted more accurately than the specified cacheable level" do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_california_usa

          expect(response).to have_http_status(:ok)
          # X-Cacheable-Client-Geo is set to all of the US, so billboards targeted at a single state are filtered out
          expect(response.parsed_body).to be_empty
        end

        it "is accurate for more precise locations" do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: { "X-Client-Geo" => "US-CA", "X-Cacheable-Client-Geo" => "US-CA" }

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(california_billboard.processed_html)
          expect(response.parsed_body).not_to include(canada_billboard.processed_html)
        end

        it "sets Vary header" do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_alberta_canada

          expect(response).to have_http_status(:ok)
          expect(response.headers["Vary"]).not_to include("X-Client-Geo")
          expect(response.headers["Vary"]).to include("X-Cacheable-Client-Geo")
        end
      end
    end
    # rubocop:enable RSpec/NestedGroups

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

    context "when billboard template is authorship_box" do
      before do
        billboard.update_column(:template, "authorship_box")
      end

      it "includes authorship box html" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
        expect(response.body).to include "crayons-bb__header relative"
      end

      it "includes custom_display_label if set" do
        billboard.update_column(:custom_display_label, "My great custom label")
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
        expect(response.body).to include "My great custom label"
      end
    end

    context "when billboard template is plain" do
      before do
        billboard.update_column(:template, "plain")
      end

      it "includes authorship box html" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
        expect(response.body).not_to include "crayons-bb__header relative"
      end
    end

    context "when the placement area is post_fixed_bottom" do
      it "contains close button" do
        billboard = create_billboard(placement_area: "post_fixed_bottom")
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_fixed_bottom")
        expect(response.body).to include "sponsorship-close-trigger-#{billboard.id}"
      end
    end

    context "when the placement area is post_body_bottom" do
      it "contains read more button when body is long" do
        billboard = create_billboard(placement_area: "post_body_bottom", body_markdown: "a " * 800)
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_body_bottom")
        expect(response.body).to include "text-styles--billboard long-bb-body"
      end

      it "does not contain read more button when body is short" do  
        billboard = create_billboard(placement_area: "post_body_bottom", body_markdown: "a " * 100)
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_body_bottom")
        expect(response.body).not_to include "text-styles--billboard long-bb-body"
      end
    end

    context "when the placement area is page_fixed_bottom" do
      let(:page) { create(:page) }

      it "contains close button" do
        billboard = create_billboard(placement_area: "page_fixed_bottom", page_id: page.id)
        get billboard_path(page_id: page.id, placement_area: "page_fixed_bottom")
        expect(response.body).to include "sponsorship-close-trigger-#{billboard.id}"
      end
    end

    context "when the placement area is feed_first" do
      it "includes sponsorship-close-trigger when there is a dismissal_sku" do
        billboard = create_billboard(placement_area: "feed_first", dismissal_sku: "DISMISS_ME")
        get billboard_path(placement_area: "feed_first")
        expect(response.body).to include "sponsorship-close-trigger-#{billboard.id}"
      end

      it "does not include sponsorship-close-trigger when there is no dismissal_sku" do
        billboard = create_billboard(placement_area: "feed_first")
        get billboard_path(placement_area: "feed_first")
        expect(response.body).not_to include "sponsorship-close-trigger-#{billboard.id}"
      end
    end

    context "when the placement area is post_sidebar" do
      it "does not contain close button" do
        billboard = create_billboard(placement_area: "post_sidebar")
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_sidebar")
        expect(response.body).not_to include "sponsorship-close-trigger-#{billboard.id}"
      end
    end

    context "when requesting test billboard" do
      let(:admin) { create(:user, :admin) }
      let!(:test_billboard) { create_billboard(id: 123, placement_area: "post_sidebar", approved: false) }

      before do
        sign_in admin
      end

      it "returns the test billboard when proper parameters are provided" do
        get article_billboard_path(
          username: article.username,
          slug: article.slug,
          placement_area: "post_sidebar",
          bb_test_placement_area: "post_sidebar",
          bb_test_id: test_billboard.id,
        )

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(test_billboard.processed_html)
      end

      it "does not return the test billboard when parameters are missing" do
        get article_billboard_path(
          username: article.username,
          slug: article.slug,
          placement_area: "post_sidebar",
          bb_test_id: test_billboard.id,
        )

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(test_billboard.processed_html)
      end

      it "does return live billboards for non-admin contexts" do
        # Create a few live billboards which should not be returned
        create_list(:billboard, 8, placement_area: "post_sidebar", approved: true, published: true)
        get article_billboard_path(
          username: article.username,
          slug: article.slug,
          placement_area: "post_sidebar",
          bb_test_placement_area: "post_sidebar",
          bb_test_id: billboard.id,
        )

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(billboard.processed_html)
      end

      it "does not return the test billboard for non-admin users" do
        sign_out admin
        sign_in create(:user)

        get article_billboard_path(
          username: article.username,
          slug: article.slug,
          placement_area: "post_sidebar",
          bb_test_placement_area: "post_sidebar",
          bb_test_id: test_billboard.id,
        )

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(test_billboard.processed_html)
      end
    end
  end
end
