require "rails_helper"

RSpec.describe "UserShow", type: :request do
  let_it_be(:user) { create(:user, email_public: true, education: "DEV University") }
  let(:doc) { Nokogiri::HTML(response.body) }
  let(:text) { doc.at('script[type="application/ld+json"]').text }
  let(:response_json) { JSON.parse(text) }
  let(:main_entity_of_page) { { "@type" => "WebPage", "@id" => URL.user(user) } }
  let(:same_as) do
    [
      "https://twitter.com/#{user.twitter_username}",
      "https://github.com/#{user.github_username}",
      user.mastodon_url,
      user.facebook_url,
      user.youtube_url,
      user.linkedin_url,
      user.behance_url,
      user.stackoverflow_url,
      user.dribbble_url,
      user.medium_url,
      user.gitlab_url,
      user.instagram_url,
      user.twitch_username,
      user.website_url,
    ]
  end

  let(:disambiguating_description) do
    [
      user.mostly_work_with,
      user.currently_hacking_on,
      user.currently_learning,
    ]
  end

  let(:works_for) { [{ "@type" => "Organization", "name" => user.employer_name, "url" => user.employer_url }] }

  describe "GET /:slug (user)" do
    before do
      user.update_columns(employment_title: "SEO", employer_name: "DEV", employer_url: "www.dev.to")
      user.update_columns(currently_learning: "Preact", mostly_work_with: "Ruby", currently_hacking_on: "JSON-LD")
      user.update_columns(mastodon_url: "www.example.com", facebook_url: "www.facebook.com/example", linkedin_url: "www.linkedin.com/company/example/")
      user.update_columns(youtube_url: "www.youtube.com/example", behance_url: "www.behance.com/example", stackoverflow_url: "www.stackoverflow.com/example")
      user.update_columns(dribbble_url: "www.dribbble.com/example", medium_url: "www.medium.com/example", gitlab_url: "www.gitlab.com/example")
      user.update_columns(instagram_url: "www.instagram.com/example", twitch_username: "Example007", website_url: "www.example.com/example")
      get user.path
    end

    it "returns a 200 status when navigating to the user's page" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the proper JSON-LD for a user" do
      expect(response_json).to include(
        "@context" => "http://schema.org",
        "@type" => "Person",
        "mainEntityOfPage" => main_entity_of_page,
        "url" => URL.user(user),
        "sameAs" => same_as,
        "image" => ProfileImage.new(user).get(width: 320),
        "name" => user.name,
        "email" => user.email,
        "jobTitle" => user.employment_title,
        "description" => user.summary,
        "disambiguatingDescription" => disambiguating_description,
        "worksFor" => works_for,
        "alumniOf" => user.education,
      )
    end
  end

  context "when user signed in" do
    before do
      sign_in user
      get user.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end

  context "when user not signed in" do
    before do
      get user.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).to include "application/ld+json"
      end
    end
  end

  context "when user not signed in but internal nav triggered" do
    before do
      get user.path + "?i=i"
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end
end
