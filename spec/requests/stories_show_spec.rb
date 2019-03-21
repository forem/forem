require "rails_helper"

RSpec.describe "StoriesShow", type: :request do
  let(:user)         { create(:user) }
  let(:article)      { create(:article, user_id: user.id) }

  describe "GET /:username/:slug" do
    context "when story is an article" do
      it "renders to appropriate page" do
        get article.path
        expect(response.body).to include CGI.escapeHTML(article.title)
      end

      it "renders to appropriate if article belongs to org" do
        article.update(organization_id: create(:organization).id)
        get article.path
        expect(response.body).to include CGI.escapeHTML(article.title)
      end

      it "redirects to appropriate if article belongs to org and user visits user version" do
        article.update(organization_id: create(:organization).id)
        get "/#{article.user.username}/#{article.slug}"
        expect(response.body).to redirect_to article.reload.path
      end

      it "renders second and third users if present" do
        user2 = create(:user)
        user3 = create(:user)
        article.update(second_user_id: user2.id, third_user_id: user3.id)
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
    end

    context "when story is a user" do
      it "renders to appropriate page if user changes username" do
        old_username = user.username
        user.update(username: "new_hotness_#{rand(10_000)}")
        get "/#{old_username}/#{article.slug}"
        expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
      end

      it "renders to appropriate page if user changes username twice" do
        old_username = user.username
        user.update(username: "new_hotness_#{rand(10_000)}")
        user.update(username: "new_new_username_#{rand(10_000)}")
        get "/#{old_username}/#{article.slug}"
        expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
      end

      it "renders to appropriate page if user changes username twice and go to middle username" do
        user.update(username: "new_hotness_#{rand(10_000)}")
        middle_username = user.username
        user.update(username: "new_new_username_#{rand(10_000)}")
        get "/#{middle_username}/#{article.slug}"
        expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
      end
    end

    context "when organization is present" do
      let(:organization) { create(:organization) }

      it "redirects to the appropriate page if given an organization's old slug" do
        original_slug = organization.slug
        organization.update(slug: "somethingnew")
        get "/#{original_slug}"
        expect(response.body).to redirect_to organization.path
      end

      it "redirects to the appropriate page if given an organization's old old slug" do
        original_slug = organization.slug
        organization.update(slug: "somethingnew")
        organization.update(slug: "anothernewslug")
        get "/#{original_slug}"
        expect(response.body).to redirect_to organization.path
      end
    end
  end
end
