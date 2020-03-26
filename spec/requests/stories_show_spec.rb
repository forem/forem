require "rails_helper"

RSpec.describe "StoriesShow", type: :request do
  let_it_be(:user)                  { create(:user) }
  let_it_be(:org, reload: true)     { create(:organization) }
  let_it_be(:article, reload: true) { create(:article, user: user) }

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
    end

    it "renders second and third users if present" do
      # 3rd user doesn't seem to get rendered for some reason
      user2 = create(:user)
      article.update(second_user_id: user2.id)
      get article.path
      expect(response.body).to include "<em>with <b><a href=\"#{user2.path}\">"
    end

    # sidebar HTML variant
    it "renders html variant" do
      html_variant = create(:html_variant, published: true, approved: true)
      get article.path + "?variant_version=1"
      expect(response.body).to include html_variant.html
    end

    it "Does not render variant when no variants published" do
      html_variant = create(:html_variant, published: false, approved: true)
      get article.path + "?variant_version=1"
      expect(response.body).not_to include html_variant.html
    end

    it "does not render html variant when user logged in" do
      html_variant = create(:html_variant, published: true, approved: true)
      sign_in user
      get article.path
      expect(response.body).not_to include html_variant.html
    end

    # Below article HTML variant
    it "renders below article html variant" do
      html_variant = create(:html_variant, published: true, approved: true, group: "article_show_below_article_cta")
      article.update_column(:body_markdown, rand(36**1000).to_s(36).to_s) # min length for article
      get article.path + "?variant_version=0"
      expect(response.body).to include html_variant.html
    end

    it "Does not render below article html variant for short article" do
      html_variant = create(:html_variant, published: true, approved: true, group: "article_show_below_article_cta")
      article.update_column(:body_markdown, rand(36**100).to_s(36).to_s) # ensure too short
      get article.path + "?variant_version=0"
      expect(response.body).not_to include html_variant.html
    end

    it "Does not render below article variant when no variants published" do
      html_variant = create(:html_variant, published: false, approved: true, group: "article_show_below_article_cta")
      get article.path + "?variant_version=0"
      expect(response.body).not_to include html_variant.html
    end

    it "does not render below article html variant when user logged in" do
      html_variant = create(:html_variant, published: true, approved: true, group: "article_show_below_article_cta")
      sign_in user
      get article.path + "?variant_version=0"
      expect(response.body).not_to include html_variant.html
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

    it "redirect to appropriate page if user changes username" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10_000)}")
      get "/#{old_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
    end

    it "redirect to appropriate page if user changes username twice" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10_000)}")
      user.update(username: "new_new_username_#{rand(10_000)}")
      get "/#{old_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
    end

    it "redirect to appropriate page if user changes username twice and go to middle username" do
      user.update(username: "new_hotness_#{rand(10_000)}")
      middle_username = user.username
      user.update(username: "new_new_username_#{rand(10_000)}")
      get "/#{middle_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
    end

    it "renders canonical url when exists" do
      article = create(:article, with_canonical_url: true)
      get article.path
      expect(response.body).to include('"canonical" href="' + article.canonical_url.to_s + '"')
    end

    it "shodoes not render canonical url when not on article model" do
      article = create(:article, with_canonical_url: false)
      get article.path
      expect(response.body).not_to include('"canonical" href="' + article.canonical_url.to_s + '"')
    end

    it "handles invalid slug characters" do
      allow(Article).to receive(:find_by).and_raise(ArgumentError)
      get article.path

      expect(response.status).to be(400)
    end

    it "has noindex if article has low score" do
      article = create(:article, score: -5)
      get article.path
      expect(response.body).to include("noindex")
    end

    it "has noindex if article has low score even with <code>" do
      article = create(:article, score: -5)
      article.update_column(:processed_html, "<code>hello</code>")
      get article.path
      expect(response.body).to include("noindex")
    end

    it "does not have noindex if article has high score" do
      article = create(:article, score: 6)
      get article.path
      expect(response.body).not_to include("noindex")
    end

    it "does not have noindex if article intermediate score and <code>" do
      article = create(:article, score: 3)
      article.update_column(:processed_html, "<code>hello</code>")
      get article.path
      expect(response.body).not_to include("noindex")
    end

    it "does not have noindex if article intermediate score and <code>" do
      article = create(:article, score: 3)
      article.user.update_column(:comments_count, 1)
      get article.path
      expect(response.body).not_to include("noindex")
    end
  end

  describe "GET /:username (org)" do
    it "redirects to the appropriate page if given an organization's old slug" do
      original_slug = org.slug
      org.update(slug: "somethingnew")
      get "/#{original_slug}"
      expect(response.body).to redirect_to org.path
    end

    it "redirects to the appropriate page if given an organization's old old slug" do
      original_slug = org.slug
      org.update(slug: "somethingnew")
      org.update(slug: "anothernewslug")
      get "/#{original_slug}"
      expect(response.body).to redirect_to org.path
    end
  end
end
