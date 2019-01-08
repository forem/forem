require "rails_helper"

RSpec.describe "StoriesShow", type: :request do
  let(:user)         { create(:user) }
  let(:article)      { create(:article, user_id: user.id) }

  describe "GET /:username/:slug" do
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

    it "renders to appropriate page if user changes username" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10000)}")
      get "/#{old_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
    end

    it "renders to appropriate page if user changes username twice" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10000)}")
      user.update(username: "new_new_username_#{rand(10000)}")
      get "/#{old_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
    end

    it "renders to appropriate page if user changes username twice and go to middle username" do
      user.update(username: "new_hotness_#{rand(10000)}")
      middle_username = user.username
      user.update(username: "new_new_username_#{rand(10000)}")
      get "/#{middle_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
    end

    it "renders second and third users if present" do
      user2 = create(:user)
      user3 = create(:user)
      article.update(second_user_id: user2.id, third_user_id: user3.id)
      get article.path
      expect(response.body).to include "<em>with <b><a href=\"#{user2.path}\">"
    end

    # rubocop:disable RSpec/ExampleLength
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
    # rubocop:enable RSpec/ExampleLength
  end

  it "renders html variant" do
    html_variant = create(:html_variant, published: true, approved: true)
    get article.path
    expect(response.body).to include html_variant.html
  end

  it "Does not render variant when no variants published" do
    html_variant = create(:html_variant, published: false, approved: true)
    get article.path
    expect(response.body).not_to include html_variant.html
  end

  it "does not render html variant when user logged in" do
    html_variant = create(:html_variant, published: true, approved: true)
    sign_in user
    get article.path
    expect(response.body).not_to include html_variant.html
  end
end
