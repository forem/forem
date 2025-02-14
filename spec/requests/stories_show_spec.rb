# spec/requests/stories_show_spec.rb

require "rails_helper"
require "request_store"

RSpec.describe "StoriesShow" do
  let(:user) { create(:user) }
  let(:org)  { create(:organization) }
  let(:article) { create(:article, user: user) }

  describe "GET /:username/:slug (articles)" do
    it "renders proper title" do
      get article.path
      expect(response.body).to include CGI.escapeHTML(article.title)
    end

    it "redirects to appropriate if article belongs to org and user visits user version" do
      old_path = article.path
      article.update(organization: org)
      get old_path
      expect(response.body).to redirect_to article.path
      expect(response).to have_http_status(:moved_permanently)
    end

    it "preserves internal nav param (i=i) upon redirect" do
      old_path = article.path
      article.update(organization: org)
      get "#{old_path}?i=i"
      expect(response.body).to redirect_to "#{article.path}?i=i"
      expect(response).to have_http_status(:moved_permanently)
    end

    it "does not have ?i=i on redirects which did not originally include it" do
      old_path = article.path
      article.update(organization: org)
      get old_path
      expect(response.body).not_to redirect_to "#{article.path}?i=i"
      expect(response).to have_http_status(:moved_permanently)
    end

    it "does not have ?i=i on redirects without that precise param" do
      old_path = article.path
      article.update(organization: org)
      get "#{old_path}?i=j"
      expect(response.body).to redirect_to article.path
      expect(response.body).not_to redirect_to "#{article.path}?i=j"
      expect(response.body).not_to redirect_to "#{article.path}?i=j"
    end

    ## Title tag
    it "renders signed-in title tag for signed-in user" do
      sign_in user
      get article.path

      title = "<title>#{CGI.escapeHTML(article.title)} - #{community_name}</title>"
      expect(response.body).to include(title)
    end

    it "renders signed-out title tag for signed-out user" do
      get article.path
      expect(response.body).to include "<title>#{CGI.escapeHTML(article.title)} - #{community_name}</title>"
    end

    # search_optimized_title_preamble

    it "renders title tag with search_optimized_title_preamble if set and not signed in" do
      article.update_column(:search_optimized_title_preamble, "Hey this is a test")
      get article.reload.path

      expected_title = "<title>Hey this is a test: #{CGI.escapeHTML(article.title)} - #{community_name}</title>"
      expect(response.body).to include(expected_title)
    end

    it "does not render title tag with search_optimized_title_preamble if set and not signed in" do
      sign_in user
      article.update_column(:search_optimized_title_preamble, "Hey this is a test")
      get article.path

      title = "<title>#{CGI.escapeHTML(article.title)} - #{community_name}</title>"
      expect(response.body).to include(title)
    end

    it "does not render preamble with search_optimized_title_preamble not signed in but not set" do
      get article.path
      expect(response.body).to include("#{CGI.escapeHTML(article.title)} - #{community_name}</title>")
    end

    it "renders title preamble with search_optimized_title_preamble if set and not signed in" do
      article.update_column(:search_optimized_title_preamble, "Hey this is a test")
      get article.reload.path
      expect(response.body).to include("<span class=\"fs-xl color-base-70 block\">Hey this is a test</span>")
    end

    it "does not render preamble with search_optimized_title_preamble if set and signed in" do
      sign_in user
      article.update_column(:search_optimized_title_preamble, "Hey this is a test")
      get article.path
      expect(response.body).not_to include("<span class=\"fs-xl color-base-70 block\">Hey this is a test</span>")
    end

    it "does not render title tag with search_optimized_title_preamble not signed in but not set" do
      get article.path
      expect(response.body).not_to include("<span class=\"fs-xl color-base-70 block\">Hey this is a test</span>")
    end

    it "renders proper wrapper content clases" do
      get article.path
      expect(response.body)
        .to include(" #{article.decorate.cached_tag_list_array.map { |tag| "articletag-#{tag}" }.join(' ')}")
      expect(response.body).to include(" articleuser-#{article.user_id}")
    end

    ###

    it "renders date-no-year if article published this year" do
      get article.path
      expect(response.body).to include "date-no-year"
    end

    it "renders date with year if article published last year" do
      article.update_column(:published_at, 1.year.ago)
      get article.path
      expect(response.body).not_to include "date-no-year"
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

    it "redirects to appropriate page if user changes username" do
      old_username = user.username
      user.update_columns(username: "new_hotness_#{rand(10_000)}", old_username: old_username,
                          old_old_username: user.old_username)
      get "/#{old_username}/#{article.slug}"
      user.reload
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
      expect(response).to have_http_status(:moved_permanently)
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
      # rubocop:disable RSpec/MessageChain
      allow(Article).to receive_message_chain(:includes, :find_by).and_raise(ArgumentError)
      # rubocop:enable RSpec/MessageChain
      get article.path

      expect(response).to have_http_status(:bad_request)
    end

    it "has noindex if article has low score" do
      article = create(:article, score: -5)
      get article.path
      expect(response.body).to include("noindex")
    end

    it "does not have noindex if article has high score" do
      article = create(:article, score: 6)
      get article.path
      expect(response.body).not_to include("noindex")
    end

    it "does not have noindex if article w/ intermediate score w/ 1 comment" do
      article = create(:article, score: 3)
      article.user.update_column(:comments_count, 1)
      get article.path
      expect(response.body).not_to include("noindex")
    end

    it "renders og:image with main image if present ahead of social" do
      article = create(:article, with_main_image: true, social_image: "https://example.com/image.jpg")
      get article.path
      expect(response.body).to include(%(property="og:image" content="#{article.main_image}"))
    end

    it "renders og:image with social if present and main image not so much" do
      article = create(:article, with_main_image: false, social_image: "https://example.com/image.jpg")
      get article.path
      expect(response.body).to include(%(property="og:image" content="#{article.social_image}"))
    end

    context "when subforem logic is triggered by RequestStore" do
      let!(:subforem)       { create(:subforem, domain: "www.example.com") }
      let!(:default_subforem) { create(:subforem, domain: "#{rand(1000)}.com") }

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

        get article.path
        expect(response).not_to have_http_status(:moved_permanently)
        expect(response.body).not_to include("href=\"#{URL.article(article)}\"")
      end

      it "redirects if article has no subforem_id and RequestStore has a non-default subforem_id" do
        allow(Subforem).to receive(:cached_id_by_domain).with("www.example.com").and_return(create(:subforem, domain: "other.com").id)

        get article.path
        expect(response).to have_http_status(:moved_permanently)
      end

      it "does not redirect if article has no subforem_id and RequestStore subforem_id == default_subforem" do
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)

        get article.path
        expect(response).not_to have_http_status(:moved_permanently)
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
  end
end
