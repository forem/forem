# spec/requests/stories_show_spec.rb

require "rails_helper"
require "request_store"

RSpec.describe "StoriesShow" do
  let(:user) { create(:user) }
  let(:org)  { create(:organization) }
  let(:article) { create(:article, user: user) }

  def create(name, *traits, **options)
    return super(:user, *traits, profile_image: nil, **options) if name == :user

    if name == :article
      options[:user] ||= user unless options.key?(:user_id)
      options[:with_tags] = false unless options.key?(:tag_list) || options.key?(:tags) || options.key?(:with_tags)
      options[:with_main_image] = false unless options.key?(:with_main_image)
    end
    super
  end

  def create_list(name, amount, *traits, **options)
    Array.new(amount) { create(name, *traits, **options) }
  end

  describe "GET /:username/:slug (articles)" do
    it "renders proper title, Mastodon share link, and current-year vs past-year date classes", :aggregate_failures do
      get article.path

      share_url = "https://s2f.kytta.dev/?text=#{CGI.escape(URL.article(article))}"
      expect(response.body).to include(CGI.escapeHTML(article.title), share_url, "date-no-year")

      article.update_column(:published_at, 1.year.ago)
      get article.path
      expect(response.body).not_to include("date-no-year")
    end

    it "redirects user-path requests for org articles with surrogate keys, narrow slug query, and ?i=i handling",
       :aggregate_failures do
      old_path = article.path
      article.update(organization: org)
      slug_queries = []
      callback = lambda do |*, payload|
        slug_queries << payload[:sql] if payload[:sql].include?(%("articles"."slug" =))
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get old_path }

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(article.path)
      expect(response.body).not_to redirect_to("#{article.path}?i=i")
      expect(response.headers["Surrogate-Key"]).to include(article.record_key, org.record_key)
      expect(slug_queries).not_to be_empty
      expect(slug_queries).to all(exclude("body_markdown").and(exclude(%("articles".*))))

      get "#{old_path}?i=i"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.body).to redirect_to("#{article.path}?i=i")

      get "#{old_path}?i=j"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.body).to redirect_to(article.path)
      expect(response.body).not_to redirect_to("#{article.path}?i=j")
    end

    it "renders the article with feed snapshots but without the embedding or search document" do
      path_queries = []
      callback = lambda do |*, payload|
        path_queries << payload[:sql] if payload[:sql].include?(%("articles"."path" =))
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get article.path }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(CGI.escapeHTML(article.title))
      expect(path_queries).not_to be_empty
      expect(path_queries).to all(
        include(%("articles"."processed_html"))
          .and(exclude("semantic_embedding"))
          .and(exclude("reading_list_document"))
          .and(include(%("articles"."cached_user")))
          .and(include(%("articles"."cached_organization"))),
      )
    end

    [false, true].each do |custom_domain|
      it "projects long_markdown without loading Markdown on #{custom_domain ? 'custom domains' : 'article paths'}",
         :aggregate_failures do
        organization = create(:organization, custom_domain: "blog.example.com") if custom_domain
        FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor[organization]) if custom_domain
        record = create(:article, user: user, organization: organization, published: true)

        markdown_cases = [
          nil, "", "a" * 900, "a" * 901, "word " * 200, " " * 950, "\u00A0" * 950, "#{' ' * 901}x"
        ]
        markdown_cases.each do |markdown|
          record.update_column(:body_markdown, markdown)
          get custom_domain ? "http://blog.example.com/#{record.slug}" : record.path

          expect(response).to have_http_status(:ok)
          loaded_article = controller.instance_variable_get(:@article).object
          expected_long_markdown = markdown.present? && markdown.size > 900
          expect(loaded_article.has_attribute?(:body_markdown)).to be(false)
          expect(loaded_article[:long_markdown]).to eq(expected_long_markdown)
          expect(response.body.include?("below-post-bb")).to eq(expected_long_markdown)
        end
      end
    end

    it "preserves the article JSON response with the narrower show projection" do
      article.update_column(:body_html, "<p>Legacy article HTML</p>")

      get article.path, headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "id" => article.id,
        "title" => article.title,
        "body_html" => "<p>Legacy article HTML</p>",
        "created_at" => article.created_at.as_json,
        "updated_at" => article.updated_at.as_json,
      )
    end

    it "renders organization and author details without the serialized feed snapshots" do
      article.update!(organization: org)

      get article.path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(CGI.escapeHTML(org.name), CGI.escapeHTML(user.name))
      expect(response.body).to include(article.processed_html_final)
      expect(response.headers["Surrogate-Key"].split).to include(article.record_key, org.record_key)
    end

    it "renders title tag and search_optimized_title_preamble based on auth state", :aggregate_failures do
      default_title = "<title>#{CGI.escapeHTML(article.title)} - #{community_name}</title>"
      preamble_title = "<title>Hey this is a test: #{CGI.escapeHTML(article.title)} - #{community_name}</title>"
      preamble_span = '<span class="fs-xl color-base-70 block">Hey this is a test</span>'

      get article.path
      expect(response.body).to include(default_title)
      expect(response.body).not_to include(preamble_span)

      sign_in user
      get article.path
      expect(response.body).to include(default_title)

      article.update_column(:search_optimized_title_preamble, "Hey this is a test")
      get article.path
      expect(response.body).to include(default_title)
      expect(response.body).not_to include(preamble_span)

      sign_out user
      get article.reload.path
      expect(response.body).to include(preamble_title, preamble_span)
    end

    it "renders wrapper content classes and reads the article's tag colors in one cache batch", :aggregate_failures do
      tagged_article = create(:article, user: user, with_tags: true)
      allow(Rails.cache).to receive(:fetch).and_call_original
      allow(Rails.cache).to receive(:fetch_multi).and_call_original

      get tagged_article.path

      tags = tagged_article.decorate.cached_tag_list_array
      tag_color_keys = tags.map { |tag| "view-helper-#{tag}/tag_colors" }
      expect(Rails.cache).to have_received(:fetch_multi).with(*tag_color_keys, expires_in: 5.hours).once
      expect(Rails.cache).not_to have_received(:fetch).with(a_string_ending_with("/tag_colors"), any_args)
      expect(response.body).to include(*tags.map { |tag| %(href="/t/#{tag}") })
      expect(response.body).to include(" #{tags.map { |tag| "articletag-#{tag}" }.join(' ')}")
      expect(response.body).to include(" articleuser-#{tagged_article.user_id}")
    end

    it "renders second and third users if present" do
      # 3rd user doesn't seem to get rendered for some reason
      user2 = create(:user)
      article.update(co_author_ids: [user2.id])
      get article.path
      expect(response.body).to include %(with <a href="#{user2.path}" class="crayons-link">)
    end

    it "renders articles of long length without breaking" do
      # This is a pretty weak test, just to exercise different lengths with no breakage
      article.update(title: (0...75).map { rand(65..90).chr }.join)
      get article.path
      article.update(title: (0...100).map { rand(65..90).chr }.join)
      get article.path
      article.update(title: (0...118).map { rand(65..90).chr }.join)
      get article.path
      expect(response.body).to include "title"
    end

    it "redirects and checks the renamed user's article with an existence query instead of loading the full row",
       :aggregate_failures do
      old_username = user.username
      user.update_columns(username: "new_hotness_#{rand(10_000)}", old_username: old_username,
                          old_old_username: user.old_username)
      queries = []
      callback = lambda { |*, payload|
        queries << payload[:sql] if payload[:sql].include?(%("articles"."slug"))
      }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/#{old_username}/#{article.slug}"
      end

      expect(response).to have_http_status(:moved_permanently)
      expect(response.body).to redirect_to("/#{user.reload.username}/#{article.slug}")
      scoped_to_user = /FROM "articles" WHERE "articles"."user_id"/
      expect(queries).to include(a_string_matching(/SELECT 1 AS one #{scoped_to_user.source}/))
      expect(queries).not_to include(a_string_matching(/SELECT "articles"\.\* #{scoped_to_user.source}/))
    end

    it "returns not found when the renamed user has no article with the slug" do
      other_user = create(:user)
      old_username = other_user.username
      other_user.update_columns(username: "new_hotness_#{rand(10_000)}", old_username: old_username)

      expect { get "/#{old_username}/#{article.slug}" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "redirects to appropriate page if user changes username twice" do
      old_username = user.username
      user.update_columns(username: "new_hotness_#{rand(10_000)}", old_username: old_username,
                          old_old_username: user.old_username)
      user.update_columns(username: "new_new_username_#{rand(10_000)}", old_username: user.username,
                          old_old_username: user.old_username)
      get "/#{old_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "redirects to appropriate page if user changes username twice and go to middle username" do
      user.update_columns(username: "new_hotness_#{rand(10_000)}", old_username: user.username,
                          old_old_username: user.old_username)
      middle_username = user.username
      user.update_columns(username: "new_new_username_#{rand(10_000)}", old_username: user.username,
                          old_old_username: user.old_username)
      get "/#{middle_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "renders canonical url when exists" do
      article = create(:article, with_canonical_url: true)
      get article.path
      expect(response.body).to include(%("canonical" href="#{article.canonical_url}"))
    end

    it "does not render canonical url when not on article model" do
      article = create(:article, with_canonical_url: false)
      get article.path
      expect(response.body).not_to include(%("canonical" href="#{article.canonical_url}"))
    end

    it "handles invalid slug characters" do
      path = article.path
      relation = instance_double(ActiveRecord::Relation)
      allow(Article).to receive(:includes).with(:organization, user: %i[profile setting roles]).and_return(relation)
      excluded_columns = %w[body_markdown semantic_embedding reading_list_document]
      selected_columns = Article.column_names - excluded_columns
      allow(relation).to receive(:select).with(*selected_columns, StoriesController::LONG_MARKDOWN_PROJECTION)
        .and_return(relation)
      allow(relation).to receive(:find_by).with(path: path).and_raise(ArgumentError)
      get path

      expect(response).to have_http_status(:bad_request)
    end

    it "renders noindex for low-score articles and omits it for high or commented intermediate scores",
       :aggregate_failures do
      article.update_column(:score, -5)
      get article.path
      expect(response.body).to include("noindex")

      article.update_column(:score, 6)
      get article.path
      expect(response.body).not_to include("noindex")

      article.update_column(:score, 3)
      user.update_column(:comments_count, 1)
      get article.path
      expect(response.body).not_to include("noindex")
    end

    it "renders og:image with main image if present ahead of social", :aggregate_failures do
      main_image = "https://example.com/main.jpg"
      social_image = "https://example.com/image.jpg"
      article.update_columns(main_image: main_image, social_image: social_image)

      get article.path
      expect(response.body).to include(%(property="og:image" content="#{main_image}"))

      article.update_column(:main_image, nil)
      get article.path
      expect(response.body).to include(%(property="og:image" content="#{social_image}"))
    end

    it "marks the pinned article as pinned while looking up the pinned article once" do
      PinnedArticle.set(article)
      allow(PinnedArticle).to receive(:id).and_call_original

      get article.path

      expect(response.body).to match(/data-pinned[\s>]/)
      expect(PinnedArticle).to have_received(:id).once
    end

    it "does not mark an article as pinned when another article is pinned" do
      PinnedArticle.set(create(:article))

      get article.path

      expect(response.body).not_to match(/data-pinned[\s>]/)
    end

    it "does not query for negative comments when the article has no comments" do
      negative_comment_queries = []
      callback = lambda do |*, payload|
        next if payload[:name] == "SCHEMA"

        negative_comment_queries << payload[:sql] if payload[:sql].include?("score < 0")
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get article.path
      end

      expect(response).to have_http_status(:ok)
      expect(negative_comment_queries).to be_empty
    end

    it "reuses the loaded comment tree for the hidden negative comments notice without a score < 0 query" do
      create(:comment, commentable: article, score: -5)
      article.reload

      negative_comment_queries = []
      callback = lambda do |*, payload|
        next if payload[:name] == "SCHEMA"

        negative_comment_queries << payload[:sql] if payload[:sql].include?("score < 0")
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get article.path
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Some comments may only be visible to logged-in visitors")
      expect(negative_comment_queries).to be_empty
    end

    it "loads the series articles with a single query when rendering the series switcher" do
      collection = create(:collection, user: user)
      series_articles = create_list(:article, 6, user: user, with_collection: collection)
      series_article = series_articles.first

      collection_queries = []
      callback = lambda do |*, payload|
        next if payload[:name] == "SCHEMA"

        collection_queries << payload[:sql] if payload[:sql].include?(%("articles"."collection_id" =))
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get series_article.path
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("series-switcher")
      expect(response.body).to include("6 Part Series")
      series_articles.each { |a| expect(response.body).to include(a.path) }
      expect(collection_queries.size).to eq(1)
    end

    context "when subforem logic is triggered by RequestStore" do
      let!(:subforem) { create(:subforem, domain: "www.example.com") }
      let!(:default_subforem) { create(:subforem) }

      before do
        # Simulate a default_subforem stored in RequestStore
        RequestStore.store[:default_subforem_id] = default_subforem.id
      end

      after do
        # Clear RequestStore for isolation
        RequestStore.store[:subforem_id] = nil
        RequestStore.store[:default_subforem_id] = nil
      end

      it "redirects if article has subforem_id that doesn't match RequestStore.store[:subforem_id]" do
        article.update_column(:subforem_id, create(:subforem, domain: "other.com").id)
        # RequestStore is set to something different

        get article.path
        expect(response).to have_http_status(:moved_permanently)
        expect(response.body).to redirect_to URL.article(article)
      end

      it "does not redirect if article.subforem_id == RequestStore.store[:subforem_id]" do
        article.update_column(:subforem_id, subforem.id)
        RequestStore.store[:subforem_id] = subforem.id
        # Set the subforem_domain to match what the middleware would set
        RequestStore.store[:subforem_domain] = subforem.domain

        get article.path
        expect(response).not_to have_http_status(:moved_permanently)
        expect(response).to have_http_status(:ok)
      end

      it "redirects if article has no subforem_id and RequestStore has a non-default subforem_id" do
        other_subforem_id = create(:subforem, domain: "other.com").id
        allow(Subforem).to receive(:cached_id_by_domain).with("www.example.com").and_return(other_subforem_id)

        article.update_column(:subforem_id, nil)
        get article.path
        expect(response).to have_http_status(:moved_permanently)
      end

      it "does not redirect if article has no subforem_id and RequestStore subforem_id == default_subforem" do
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)

        article.update_column(:subforem_id, nil)
        get article.path
        expect(response).not_to have_http_status(:moved_permanently)
      end
    end
  end

  describe "GET /:username/:slug (unpublished or scheduled preview redirect)" do
    let(:unpublished_article) { create(:article, user: user, published: false) }
    let(:scheduled_article) { create(:article, user: user, published: true, published_at: 1.day.from_now) }
    let(:other_user) { create(:user) }
    let(:admin_user) { create(:user, :admin) }

    context "when user is not signed in" do
      it "raises 404 without a valid preview param and renders uncached with a valid preview param",
         :aggregate_failures do
        expect { get unpublished_article.path }.to raise_error(ActiveRecord::RecordNotFound)
        expect { get "#{unpublished_article.path}?preview=invalid" }.to raise_error(ActiveRecord::RecordNotFound)
        expect { get scheduled_article.path }.to raise_error(ActiveRecord::RecordNotFound)

        get "#{unpublished_article.path}?preview=#{unpublished_article.password}"
        expect(response).to have_http_status(:ok)
        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.headers["Cache-Control"]).to include("private")
      end
    end

    context "when user is signed in without edit permissions" do
      before { sign_in other_user }

      it "raises 404 for unpublished and scheduled articles without a valid preview param", :aggregate_failures do
        expect { get unpublished_article.path }.to raise_error(ActiveRecord::RecordNotFound)
        expect { get "#{unpublished_article.path}?preview=invalid" }.to raise_error(ActiveRecord::RecordNotFound)
        expect { get scheduled_article.path }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when user is signed in as the author" do
      before { sign_in user }

      it "redirects unpublished and scheduled articles to the preview URL while preserving query params",
         :aggregate_failures do
        get unpublished_article.path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("#{unpublished_article.path}?preview=#{unpublished_article.password}")
        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.headers["Cache-Control"]).to include("private")

        get "#{unpublished_article.path}?preview=wrong_token"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("#{unpublished_article.path}?preview=#{unpublished_article.password}")
        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.headers["Cache-Control"]).to include("private")

        get "#{unpublished_article.path}?i=i"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("#{unpublished_article.path}?i=i&preview=#{unpublished_article.password}")

        get scheduled_article.path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("#{scheduled_article.path}?preview=#{scheduled_article.password}")
        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.headers["Cache-Control"]).to include("private")
      end
    end

    context "when user is signed in as an admin" do
      before { sign_in admin_user }

      it "redirects unpublished article without preview param to preview URL" do
        get unpublished_article.path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("#{unpublished_article.path}?preview=#{unpublished_article.password}")
        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.headers["Cache-Control"]).to include("private")
      end
    end

    context "when user is an organization admin for an org unpublished article" do
      let(:org_admin) { create(:user) }
      let(:org_unpublished_article) { create(:article, user: user, organization: org, published: false) }

      before do
        create(:organization_membership, user: org_admin, organization: org, type_of_user: :admin)
        sign_in org_admin
      end

      it "redirects unpublished article to preview URL" do
        get org_unpublished_article.path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("#{org_unpublished_article.path}?preview=#{org_unpublished_article.password}")
        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.headers["Cache-Control"]).to include("private")
      end
    end

    context "when author is suspended" do
      before do
        user.add_role(:suspended)
        sign_in user
      end

      it "raises 404 for unpublished article without preview param" do
        expect { get unpublished_article.path }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when on a custom domain" do
      let(:custom_org) { create(:organization, custom_domain: "custom.example.com") }
      let(:custom_article) { create(:article, user: user, organization: custom_org, published: false) }

      before do
        sign_in user
      end

      it "redirects to custom domain preview URL for authorized user" do
        get "/#{custom_article.slug}",
            headers: { "Host" => "custom.example.com" },
            env: { "forem.custom_domain_org" => custom_org }
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("/#{custom_article.slug}?preview=#{custom_article.password}")
        expect(response.headers["Surrogate-Control"]).to be_nil
        expect(response.headers["Cache-Control"]).to include("private")
      end
    end
  end

  describe "GET /:username (org)" do
    it "redirects to the appropriate page if given an organization's old slug" do
      original_slug = org.slug
      org.update(slug: "somethingnew")
      get "/#{original_slug}"
      expect(response.body).to redirect_to org.path
      expect(response).to have_http_status(:moved_permanently)
    end

    it "redirects to the appropriate page if given an organization's old old slug" do
      original_slug = org.slug
      org.update(slug: "somethingnew")
      org.update(slug: "anothernewslug")
      get "/#{original_slug}"
      expect(response.body).to redirect_to org.path
      expect(response).to have_http_status(:moved_permanently)
    end

    context "when the organization has a cover image" do
      before { org.update!(cover_image: fixture_file_upload("800x600.png", "image/png")) }

      it "serves the cover at 1600px for 1x screens and 3200px for 2x screens" do
        allow(Images::Optimizer).to receive(:call).and_call_original

        get org.path

        expect(response).to have_http_status(:ok)
        expect(Images::Optimizer).to have_received(:call)
          .with(a_string_including("organization/cover_image/#{org.id}"), hash_including(width: 1600))
        expect(Images::Optimizer).to have_received(:call)
          .with(a_string_including("organization/cover_image/#{org.id}"), hash_including(width: 3200))
        expect(response.body).to include("image-set(")
      end
    end

    context "with comment cue popup data attributes" do
      it "renders cue data attributes when the flag is fully enabled globally" do
        allow(FeatureFlag).to receive(:enabled?).and_call_original
        allow(FeatureFlag).to receive(:enabled?).with(:comment_cue_popup).and_return(true)

        get article.path

        expect(response.body).to include("data-cue-message=")
        expect(response.body).to include("data-cue-close-label=")
      end

      it "omits cue data attributes when the flag is off" do
        allow(FeatureFlag).to receive(:enabled?).and_call_original
        allow(FeatureFlag).to receive(:enabled?).with(:comment_cue_popup).and_return(false)

        get article.path

        expect(response.body).not_to include("data-cue-message=")
        expect(response.body).not_to include("data-cue-close-label=")
      end
    end

    it "renders the organization's generated social_image in og:image and twitter:image:src when present" do
      org.update_column(:social_image, "https://example.com/org-social-card.png")

      get org.path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('property="og:image" content="https://example.com/org-social-card.png"')
      expect(response.body).to include('name="twitter:image:src" content="https://example.com/org-social-card.png"')
    end
  end

  describe "GET /:username (user)" do
    it "renders the user's generated social_image in og:image and twitter:image:src when present" do
      user.profile.update_column(
        :data,
        user.profile.data.merge("social_image" => "https://example.com/user-social-card.png"),
      )

      get user.path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('property="og:image" content="https://example.com/user-social-card.png"')
      expect(response.body).to include('name="twitter:image:src" content="https://example.com/user-social-card.png"')
    end

    it "falls back to Settings::General.main_social_image when social_image is blank" do
      allow(Settings::General).to receive(:main_social_image).and_return("https://example.com/default-main-social.png")

      get user.path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('property="og:image" content="https://example.com/default-main-social.png"')
    end
  end
end
