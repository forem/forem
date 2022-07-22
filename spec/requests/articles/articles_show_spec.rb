require "rails_helper"

RSpec.describe "ArticlesShow", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, published: true, organization: organization) }
  let(:organization) { create(:organization) }
  let(:doc) { Nokogiri::HTML(response.body) }
  let(:text) { doc.at('script[type="application/ld+json"]').text }
  let(:response_json) { JSON.parse(text) }

  describe "GET /:slug (articles)" do
    before do
      allow(Settings::General).to receive(:logo_png).and_return("logo.png")
      get article.path
    end

    it "returns a 200 status when navigating to the article's page" do
      expect(response).to have_http_status(:ok)
    end

    # rubocop:disable RSpec/ExampleLength
    it "renders the proper JSON-LD for an article" do
      expect(response_json).to include(
        "@context" => "http://schema.org",
        "@type" => "Article",
        "mainEntityOfPage" => {
          "@type" => "WebPage",
          "@id" => URL.article(article)
        },
        "url" => URL.article(article),
        "image" => [
          ApplicationController.helpers.article_social_image_url(article, width: 1080, height: 1080),
          ApplicationController.helpers.article_social_image_url(article, width: 1280, height: 720),
          ApplicationController.helpers.article_social_image_url(article, width: 1600, height: 900),
        ],
        "publisher" => {
          "@context" => "http://schema.org",
          "@type" => "Organization",
          "name" => Settings::Community.community_name.to_s,
          "logo" => {
            "@context" => "http://schema.org",
            "@type" => "ImageObject",
            "url" => ApplicationController.helpers.optimized_image_url(Settings::General.logo_png, width: 192,
                                                                                                   fetch_format: "png"),
            "width" => "192",
            "height" => "192"
          }
        },
        "headline" => article.title,
        "author" => {
          "@context" => "http://schema.org",
          "@type" => "Person",
          "url" => URL.user(user),
          "name" => user.name
        },
        "datePublished" => article.published_timestamp,
        "dateModified" => article.published_timestamp,
      )
    end

    it "renders 'posted on' information" do
      get article.path
      expect(response.body).to include("Posted on")
      expect(response.body).not_to include("Scheduled for")
    end
  end

  describe "GET /:username/:slug (scheduled)" do
    let(:scheduled_article) { create(:article, published: true, published_at: Date.tomorrow) }
    let(:query_params) { "?preview=#{scheduled_article.password}" }
    let(:scheduled_article_path) { scheduled_article.path + query_params }

    it "renders a scheduled article with the article password" do
      get scheduled_article_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(scheduled_article.title)
    end

    it "renders 'scheduled for' information" do
      get scheduled_article_path
      expect(response.body).to include("Scheduled for")
      expect(response.body).not_to include("Posted on")
    end

    it "doesn't show edit link when user is not signed in" do
      get scheduled_article_path
      expect(response.body).not_to include("Click to edit")
    end

    it "renders 404 for a scheduled article w/o article password" do
      expect { get scheduled_article.path }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  it "renders the proper organization for an article when one is present" do
    get organization.path
    expect(response_json).to include(
      {
        "@context" => "http://schema.org",
        "@type" => "Organization",
        "mainEntityOfPage" => {
          "@type" => "WebPage",
          "@id" => URL.organization(organization)
        },
        "url" => URL.organization(organization),
        "image" => organization.profile_image_url_for(length: 320),
        "name" => organization.name,
        "description" => organization.summary
      },
    )
  end
  # rubocop:enable RSpec/ExampleLength

  context "when keywords are set" do
    it "shows keywords" do
      allow(Settings::General).to receive(:meta_keywords).and_return({ article: "hello, world" })
      article.update_column(:cached_tag_list, "super sheep")
      get article.path
      expect(response.body).to include('<meta name="keywords" content="super sheep, hello, world">')
    end
  end

  context "when keywords are not" do
    it "does not show keywords" do
      allow(Settings::General).to receive(:meta_keywords).and_return({ article: "" })
      article.update_column(:cached_tag_list, "super sheep")
      get article.path
      expect(response.body).not_to include(
        '<meta name="keywords" content="super sheep, hello, world">',
      )
    end
  end

  context "when user signed in" do
    before do
      sign_in user
      get article.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end

  context "when user not signed in" do
    before do
      get article.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).to include "application/ld+json"
      end
    end
  end

  context "when user not signed in but internal nav triggered" do
    before do
      get "#{article.path}?i=i"
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end
end
