require "rails_helper"

RSpec.describe "Billboards" do
  let(:user)    { create(:user) }
  let(:article) { create(:article, user: user, tags: "") }

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
        expect(response.body).to include(targeted_billboard.processed_html)
      end
    end

    context "when exclude_role_names includes user's role" do
      let!(:excluded_billboard) { create_billboard(placement_area: "post_comments", exclude_role_names: ["moderator"]) }

      it "excludes billboards that should not be shown to user's role" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(excluded_billboard.processed_html)
      end
    end

    context "when target_role_names does not include user's role" do
      let!(:non_targeted_billboard) do
        create_billboard(placement_area: "post_comments", target_role_names: ["admin"],
                         body_markdown: rand(10_000).to_s)
      end

      it "excludes billboards that do not target user's role" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(non_targeted_billboard.processed_html)
      end
    end

    context "when exclude_role_names does not include user's role" do
      let!(:non_excluded_billboard) { create_billboard(placement_area: "post_comments", exclude_role_names: ["admin"]) }

      it "includes billboards that are not excluded for user's role" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(non_excluded_billboard.processed_html)
      end
    end

    context "when both target_role_names and exclude_role_names are empty" do
      let!(:open_billboard) { create_billboard(placement_area: "post_comments") }

      it "includes billboards that have no role restrictions" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(open_billboard.processed_html)
      end
    end
  end

  describe "GET /:username/:slug/billboards/:color" do
    context "when placement_area includes 'fixed_'" do
      let!(:billboard) { create_billboard(placement_area: "post_fixed_bottom") }

      it "includes the correct style string" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_fixed_bottom")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("border: 1px solid #{billboard.color}; border-bottom: none")
      end
    end

    context "when placement_area does not include 'fixed_'" do
      let!(:billboard) { create_billboard(placement_area: "post_comments") }

      it "includes the correct style string" do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("border: 1px solid #{billboard.color}")
      end
    end

    context "when color is blank" do
      it "returns an empty style string" do
        create_billboard(placement_area: "post_comments", color: "")
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("border-top: calc(9px + 0.5vw) solid")
        expect(response.body).not_to include("border: 1px solid")
      end
    end
  end

  describe "GET /:username/:slug/billboards/:placement_area" do
    let(:billboard) { create_billboard(placement_area: "post_comments") }

    it "returns the correct response" do
      billboard
      get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(billboard.processed_html)
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

        it "returns only billboards targeting their location and does not set Vary header", :aggregate_failures do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_alberta_canada

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(canada_billboard.processed_html)
          expect(response.body).not_to include(california_billboard.processed_html)
          expect(response.headers["Vary"]).not_to include("X-Client-Geo", "X-Cacheable-Client-Geo")
        end

        it "is accurate for more precise locations" do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_california_usa

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(california_billboard.processed_html)
          expect(response.body).not_to include(canada_billboard.processed_html)
        end
      end

      context "without signed-in user" do
        it "filters billboards more specific than cacheable geo and sets Vary header", :aggregate_failures do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: client_in_california_usa

          expect(response).to have_http_status(:ok)
          # X-Cacheable-Client-Geo is set to all of the US, so billboards targeted at a single state are filtered out
          expect(response.body).to be_empty
          expect(response.headers["Vary"]).not_to include("X-Client-Geo")
          expect(response.headers["Vary"]).to include("X-Cacheable-Client-Geo")
        end

        it "is accurate for more precise locations" do
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left"),
              headers: { "X-Client-Geo" => "US-CA", "X-Cacheable-Client-Geo" => "US-CA" }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(california_billboard.processed_html)
          expect(response.body).not_to include(canada_billboard.processed_html)
        end
      end
    end
    # rubocop:enable RSpec/NestedGroups

    context "when signed in" do
      it "does not set surrogate key, x-accel-expires, or Fastly cache control headers", :aggregate_failures do
        billboard
        sign_in user
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response.headers["Surrogate-key"]).to be_nil
        expect(response.headers["x-accel-expires"]).to be_nil
        expect(response.headers.to_hash).not_to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end

    context "when signed out" do
      it "sets surrogate keys, x-accel-expires, and Fastly cache control headers", :aggregate_failures do
        billboard
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response.headers["Surrogate-Key"].split).to eq(
          ["display_ads/#{billboard.id}", "billboard_responses", "billboard_responses/post_comments"],
        )
        expect(response.headers["X-Accel-Expires"]).to eq(max_age.to_s)
        expect(response.headers.to_hash).to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end

    context "when signed out with custom cache expiry config" do
      let(:custom_cache_expiry) { 600 } # 10 minutes

      before do
        BillboardPlacementAreaConfig.create!(
          placement_area: "post_comments",
          signed_in_rate: 100,
          signed_out_rate: 100,
          cache_expiry_seconds: custom_cache_expiry,
        )
      end

      it "uses the configured cache expiry in x-accel-expires and surrogate control headers", :aggregate_failures do
        billboard
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response.headers["X-Accel-Expires"]).to eq(custom_cache_expiry.to_s)
        expect(response.headers["Surrogate-Control"]).to eq(
          "max-age=#{custom_cache_expiry}, stale-if-error=#{stale_if_error}",
        )
      end

      it "uses different cache expiry for different placement areas" do
        create_billboard(placement_area: "sidebar_left")
        BillboardPlacementAreaConfig.create!(
          placement_area: "sidebar_left",
          signed_in_rate: 100,
          signed_out_rate: 100,
          cache_expiry_seconds: 120, # 2 minutes
        )

        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "sidebar_left")

        expect(response.headers["X-Accel-Expires"]).to eq("120")
        expect(response.headers["Surrogate-Control"]).to eq("max-age=120, stale-if-error=#{stale_if_error}")
      end

      it "uses zero cache expiry when configured" do
        billboard
        BillboardPlacementAreaConfig.find_by(placement_area: "post_comments").update!(cache_expiry_seconds: 0)

        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response.headers["X-Accel-Expires"]).to eq("0")
        expect(response.headers["Surrogate-Control"]).to eq("max-age=0, stale-if-error=#{stale_if_error}")
      end

      it "uses default cache expiry for placement areas without config" do
        create_billboard(placement_area: "post_sidebar")

        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_sidebar")

        default_expiry = BillboardPlacementAreaConfig::DEFAULT_BILLBOARD_CACHE_EXPIRY_SECONDS
        expect(response.headers["X-Accel-Expires"]).to eq(default_expiry.to_s)
        expect(response.headers["Surrogate-Control"]).to eq(
          "max-age=#{default_expiry}, stale-if-error=#{stale_if_error}",
        )
      end
    end

    context "when the placement area is not hidden by default" do
      it "tags the billboard with its placement area without hiding it" do
        billboard
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response.body).to include('data-placement-area="post_comments"')
        expect(response.body).not_to include("data-placement-hidden")
      end
    end

    # rubocop:disable RSpec/NestedGroups
    context "when the placement area is hidden by default" do
      before do
        BillboardPlacementAreaConfig.create!(placement_area: "post_comments", hidden_by_default: true)
      end

      it "still delivers the billboard, rendered hidden and tagged with its placement area" do
        billboard
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response.body).to include(billboard.processed_html)
        expect(response.body).to include('data-placement-area="post_comments"')
        expect(response.body).to include('data-placement-hidden="true"')
      end

      it "hides the plain template" do
        billboard.update_column(:template, "plain")

        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response.body).to include('data-placement-hidden="true"')
      end

      it "hides the minimized version of a persistent billboard too" do
        create_billboard(placement_area: "post_fixed_bottom", special_behavior: "persistent",
                         minimized_body_markdown: "Minimized content")
        BillboardPlacementAreaConfig.create!(placement_area: "post_fixed_bottom", hidden_by_default: true)

        get article_billboard_path(username: article.username, slug: article.slug,
                                   placement_area: "post_fixed_bottom")

        expect(response.body).to include("js-minimized-template")
        expect(response.body.scan('data-placement-hidden="true"').size).to eq(2)
      end

      %w[feed_first post_fixed_bottom post_body_bottom post_sidebar].each do |area|
        it "hides the #{area} template" do
          create_billboard(placement_area: area)
          BillboardPlacementAreaConfig.create!(placement_area: area, hidden_by_default: true)

          get article_billboard_path(username: article.username, slug: article.slug, placement_area: area)

          expect(response.body).to include("data-placement-area=\"#{area}\"")
          expect(response.body).to include('data-placement-hidden="true"')
        end
      end

      context "with fragment caching enabled" do
        around do |example|
          original_cache_store = ActionController::Base.cache_store
          original_perform_caching = ActionController::Base.perform_caching

          ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
          ActionController::Base.perform_caching = true

          example.run
        ensure
          ActionController::Base.perform_caching = original_perform_caching
          ActionController::Base.cache_store = original_cache_store
        end

        it "reflects a visibility change without waiting for the billboard cache to expire" do
          billboard
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
          expect(response.body).to include('data-placement-hidden="true"')

          BillboardPlacementAreaConfig.find_by(placement_area: "post_comments").update!(hidden_by_default: false)

          get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
          expect(response.body).to include(billboard.processed_html)
          expect(response.body).not_to include("data-placement-hidden")
        end
      end
    end
    # rubocop:enable RSpec/NestedGroups

    context "when billboard template is authorship_box" do
      it "includes authorship box html and custom_display_label if set", :aggregate_failures do
        billboard.update_columns(template: "authorship_box", custom_display_label: "My great custom label")
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
        expect(response.body).to include("crayons-bb__header relative")
        expect(response.body).to include("My great custom label")
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
        create_billboard(placement_area: "post_body_bottom", body_markdown: "a " * 800)
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_body_bottom")
        expect(response.body).to include "text-styles--billboard long-bb-body"
      end

      it "does not contain read more button when body is short" do
        create_billboard(placement_area: "post_body_bottom", body_markdown: "a " * 100)
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_body_bottom")
        expect(response.body).not_to include "text-styles--billboard long-bb-body"
      end
    end

    context "when the placement area is post_body_bottom_secondary" do
      it "renders with the below-post body billboard styling" do
        billboard = create_billboard(placement_area: "post_body_bottom_secondary", body_markdown: "a " * 800)
        get article_billboard_path(username: article.username, slug: article.slug,
                                   placement_area: "post_body_bottom_secondary")
        expect(response.body).to include("body-billboard")
        expect(response.body).to include("text-styles--billboard long-bb-body")
        expect(response.body).to include(%(data-id="#{billboard.id}"))
      end
    end

    %w[post_sidebar_secondary post_comments_secondary].each do |area|
      context "when the placement area is #{area}" do
        it "returns only billboards for the secondary area" do
          primary = create_billboard(placement_area: area.delete_suffix("_secondary"))
          secondary = create_billboard(placement_area: area)
          get article_billboard_path(username: article.username, slug: article.slug, placement_area: area)
          expect(response.body).to include(%(data-id="#{secondary.id}"))
          expect(response.body).not_to include(%(data-id="#{primary.id}"))
        end
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
      let(:test_billboard) { create_billboard(id: 123, placement_area: "post_sidebar", approved: false) }

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
        create_billboard(placement_area: "post_sidebar")
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
        sign_in user

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

  describe "GET /:username/:slug/billboards/:placement_area with article exclusion" do
    let(:article2) { create(:article, user: create(:user), slug: article.slug, tags: "") }

    context "when billboard excludes the current article" do
      let!(:billboard) { create_billboard(placement_area: "post_comments", exclude_article_ids: [article.id]) }

      it "excludes the billboard only for the excluded article when another shares its slug", :aggregate_failures do
        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty

        get article_billboard_path(username: article2.username, slug: article2.slug, placement_area: "post_comments")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(billboard.processed_html)
      end
    end
  end

  describe "GET /:username/:slug/billboards/:placement_area article targeting" do
    def get_article_billboard(target_article = article)
      get article_billboard_path(username: target_article.username, slug: target_article.slug,
                                 placement_area: "post_comments")
    end

    it "does not load the article's large columns" do
      article
      create_billboard(placement_area: "post_comments")
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('FROM "articles"') }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get_article_billboard }

      expect(queries).not_to be_empty
      expect(queries.join("\n")).not_to include('"articles".*', "processed_html", "body_markdown")
    end

    it "targets billboards by the article's tags" do
      ruby_billboard = create_billboard(placement_area: "post_comments", tag_list: "ruby")

      get_article_billboard(create(:article, user: user, tags: "ruby"))

      expect(response.body).to include(ruby_billboard.processed_html)
    end

    it "serves community billboards of the article's organization" do
      organization = create(:organization)
      org_article = create(:article, user: user, organization: organization, tags: "")
      community_billboard = create_billboard(placement_area: "post_comments", type_of: :community,
                                             organization: organization)
      create_billboard(placement_area: "post_comments", type_of: :in_house)

      get_article_billboard(org_article)

      expect(response.body).to include(community_billboard.processed_html)
    end

    it "does not serve external billboards when a co-author opts out of adjacent sponsors" do
      co_author = create(:user)
      co_author.setting.update!(permit_adjacent_sponsors: false)
      article.update!(co_author_ids: [co_author.id])
      create_billboard(placement_area: "post_comments", type_of: :external)

      get_article_billboard

      expect(response.body).to be_empty
    end
  end

  describe "GET /:username/:slug/billboards/:placement_area viewer country and anonymous tracking" do
    let!(:billboard) { create_billboard(placement_area: "post_comments") }
    let(:billboard_element) { Nokogiri::HTML(response.body).at_css("[data-display-unit]") }

    def get_billboard(headers)
      get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments"),
          headers: headers
    end

    context "when signed in" do
      it "sends the country from viewer precise location and disallows anonymous tracking", :aggregate_failures do
        allow(Settings::General).to receive(:geos_with_allowed_anonymous_tracking).and_return(["CA"])
        sign_in user
        get_billboard("X-Client-Geo" => "CA-AB", "X-Cacheable-Client-Geo" => "")

        expect(billboard_element["data-id"]).to eq(billboard.id.to_s)
        expect(billboard_element["data-viewer-country"]).to eq("CA")
        expect(billboard_element["data-anonymous-tracking-allowed"]).to be_nil
      end
    end

    context "when signed out without location targeting or anonymous tracking regions" do
      it "neither varies the edge cache on location nor sends location data" do
        get_billboard("X-Client-Geo" => "US-CA", "X-Cacheable-Client-Geo" => "US")

        expect(response.headers["Vary"].to_s).not_to include("X-Cacheable-Client-Geo")
        expect(billboard_element["data-id"]).to eq(billboard.id.to_s)
        expect(billboard_element["data-viewer-country"]).to be_nil
        expect(billboard_element["data-anonymous-tracking-allowed"]).to be_nil
      end
    end

    context "when signed out with location targeting enabled" do
      before do
        allow(FeatureFlag).to receive(:enabled?).and_call_original
        allow(FeatureFlag).to receive(:enabled?).with(Geolocation::FEATURE_FLAG).and_return(true)
      end

      it "sends the country from the cacheable location the response varies on" do
        get_billboard("X-Client-Geo" => "US-CA", "X-Cacheable-Client-Geo" => "US-CA")

        expect(response.headers["Vary"]).to include("X-Cacheable-Client-Geo")
        expect(billboard_element["data-viewer-country"]).to eq("US")
        expect(billboard_element["data-anonymous-tracking-allowed"]).to be_nil
      end
    end

    context "when signed out with anonymous tracking regions" do
      before do
        allow(Settings::General).to receive(:geos_with_allowed_anonymous_tracking).and_return(%w[us GB-SCT])
      end

      it "varies on location, sends country, and disallows tracking outside allowed regions", :aggregate_failures do
        get_billboard("X-Client-Geo" => "FR", "X-Cacheable-Client-Geo" => "FR")

        expect(response.headers["Vary"]).to include("X-Cacheable-Client-Geo")
        expect(billboard_element["data-viewer-country"]).to eq("FR")
        expect(billboard_element["data-anonymous-tracking-allowed"]).to be_nil
      end

      it "allows anonymous tracking in an allowed country, including its regions" do
        get_billboard("X-Client-Geo" => "US-NY", "X-Cacheable-Client-Geo" => "US-NY")

        expect(billboard_element["data-anonymous-tracking-allowed"]).to eq("true")
      end

      it "allows anonymous tracking in an allowed region" do
        get_billboard("X-Client-Geo" => "GB-SCT", "X-Cacheable-Client-Geo" => "GB-SCT")

        expect(billboard_element["data-anonymous-tracking-allowed"]).to eq("true")
      end

      it "does not allow a whole country when only one of its regions is allowed" do
        get_billboard("X-Client-Geo" => "GB-ENG", "X-Cacheable-Client-Geo" => "GB")

        expect(billboard_element["data-anonymous-tracking-allowed"]).to be_nil
      end

      it "does not allow anonymous tracking when the edge has no cacheable location" do
        # Fastly leaves this blank for countries outside its active_geofencing_regions dictionary
        get_billboard("X-Client-Geo" => "US-NY", "X-Cacheable-Client-Geo" => "")

        expect(billboard_element["data-viewer-country"]).to be_nil
        expect(billboard_element["data-anonymous-tracking-allowed"]).to be_nil
      end
    end
  end

  describe "GET /bb/:placement_area for a fully cached placement area" do
    let!(:billboard) { create_billboard(placement_area: "post_comments") }
    let(:billboard_element) { Nokogiri::HTML(response.body).at_css("[data-display-unit]") }

    before do
      BillboardPlacementAreaConfig.create!(placement_area: "post_comments", fully_cached: true)
    end

    context "when signed in" do
      before do
        # Like a returning signed-in browser: the user is restored from their session rather than
        # freshly logged in, and the request carries the remember-me cookie Fastly uses to keep
        # signed-in and signed-out copies of every response apart.
        login_as(user, scope: :user, run_callbacks: false)
        cookies["remember_user_token"] = "token"
      end

      it "caches the response at the edge without setting any cookies" do
        get billboard_path(placement_area: "post_comments")

        expect(response.body).to include(billboard.processed_html)
        expect(response.headers.to_hash).to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
        expect(response.headers["Surrogate-Key"].split).to include(billboard.record_key)
        expect(response.headers["Set-Cookie"]).to be_blank
      end

      it "does not cache a response that sets cookies, like a refreshed remember-me cookie" do
        # A fresh login (as from the remember-me cookie after a session expires) makes Devise
        # refresh that cookie, which must never reach other visitors through a cached response.
        login_as(user, scope: :user, event: :authentication)

        get billboard_path(placement_area: "post_comments")

        expect(response.headers["Set-Cookie"]).to include("remember_user_token")
        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.headers["Cache-Control"]).not_to include("public")
        expect(response.body).to include(billboard.processed_html)
      end

      it "does not serve billboards that target something about the individual request" do
        billboard.update!(tag_list: "ruby")

        get billboard_path(placement_area: "post_comments")

        expect(response.body).to be_empty
      end

      it "still respects whether the visitor is signed in" do
        billboard.update!(display_to: :logged_out)

        get billboard_path(placement_area: "post_comments")

        expect(response.body).to be_empty
      end

      it "uses the same cacheable location as signed-out visitors and varies on it" do
        allow(FeatureFlag).to receive(:enabled?).and_call_original
        allow(FeatureFlag).to receive(:enabled?).with(Geolocation::FEATURE_FLAG).and_return(true)

        get billboard_path(placement_area: "post_comments"),
            headers: { "X-Client-Geo" => "CA-AB", "X-Cacheable-Client-Geo" => "US" }

        expect(response.headers["Vary"]).to include("X-Cacheable-Client-Geo")
        expect(billboard_element["data-viewer-country"]).to eq("US")
        expect(billboard_element["data-anonymous-tracking-allowed"]).to be_nil
      end

      it "serves requests that carry article context as before, uncached" do
        billboard.update!(tag_list: "ruby")

        get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")

        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.body).to be_empty # article isn't tagged ruby, so the article context applied
      end

      it "keeps serving article areas requested without an article as shared once no longer fully cached" do
        # Such requests come from pages rendered while the area was fully cached, which can
        # outlive the switch. They have no article, so article-targeted billboards must stay out.
        BillboardPlacementAreaConfig.find_by(placement_area: "post_comments").update!(fully_cached: false)
        billboard.update!(tag_list: "ruby")

        get billboard_path(placement_area: "post_comments")

        expect(response.headers["Surrogate-Control"]).to eq("max-age=#{max_age}, stale-if-error=#{stale_if_error}")
        expect(response.body).to be_empty
      end

      it "serves other placement areas requested without context as before when not fully cached" do
        sidebar_billboard = create_billboard(placement_area: "sidebar_left", tag_list: "ruby")

        get billboard_path(placement_area: "sidebar_left")

        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.body).to include(sidebar_billboard.processed_html)
      end
    end

    context "when signed out" do
      it "tags even an empty response so the placement area's cached responses can be purged" do
        billboard.update!(tag_list: "ruby")

        get billboard_path(placement_area: "post_comments")

        expect(response.body).to be_empty
        expect(response.headers["Surrogate-Key"].split).to eq(%w[billboard_responses billboard_responses/post_comments])
      end

      it "caches the response without varying on location when nothing depends on it" do
        get billboard_path(placement_area: "post_comments"),
            headers: { "X-Client-Geo" => "US-CA", "X-Cacheable-Client-Geo" => "US" }

        expect(response.body).to include(billboard.processed_html)
        expect(response.headers["Surrogate-Control"]).to eq("max-age=#{max_age}, stale-if-error=#{stale_if_error}")
        expect(response.headers["Vary"].to_s).not_to include("X-Cacheable-Client-Geo")
        expect(billboard_element["data-viewer-country"]).to be_nil
      end
    end
  end

  describe "GET /bb/external_feed for an embedding site" do
    let!(:billboard) { create_billboard(placement_area: "external_feed", template: "authorship_box") }
    let(:billboard_element) { Nokogiri::HTML(response.body).at_css("[data-display-unit]") }

    it "renders the billboard without Forem's markup, tracked as an embed, and lets any origin read it",
       :aggregate_failures do
      get billboard_path(placement_area: "external_feed"), headers: { "Origin" => "https://embed.example.com" }

      expect(response.body).to include(billboard.processed_html)
      expect(response.body).not_to include("crayons-bb__header")
      expect(billboard_element["data-context-type"]).to eq(BillboardEvent::CONTEXT_TYPE_EMBED)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    end
  end

  describe "GET /:username/:slug/billboards/:placement_area with adjacent sponsor preferences" do
    let!(:external_billboard) { create_billboard(placement_area: "post_comments", type_of: :external) }

    def get_contextual_billboard
      get article_billboard_path(username: article.username, slug: article.slug, placement_area: "post_comments")
    end

    it "shows external billboards when permitted and answers the preference without a separate users_settings query",
       :aggregate_failures do
      article
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get_contextual_billboard }

      expect(queries.grep(/FROM "users_settings"/)).to be_empty
      expect(response.body).to include(external_billboard.processed_html)
    end

    it "hides external billboards when the author opts out" do
      user.setting.update_column(:permit_adjacent_sponsors, false)

      get_contextual_billboard

      expect(response.body).not_to include(external_billboard.processed_html)
    end

    it "hides external billboards when a co-author's setting is nil" do
      co_author = create(:user)
      co_author.setting.update_column(:permit_adjacent_sponsors, nil)
      article.update_column(:co_author_ids, [co_author.id])

      get_contextual_billboard

      expect(response.body).not_to include(external_billboard.processed_html)
    end
  end
end
