require "rails_helper"

RSpec.describe "UserShow", type: :request do
  let_it_be(:user) { create(:user, :with_all_info, email_public: true) }
  let(:doc) { Nokogiri::HTML(response.body) }
  let(:text) { doc.at('script[type="application/ld+json"]').text }
  let(:response_json) { JSON.parse(text) }

  describe "GET /:slug (user)" do
    before do
      get user.path
    end

    it "returns a 200 status when navigating to the user's page" do
      expect(response).to have_http_status(:ok)
    end

    # rubocop:disable Rspec/ExampleLength
    it "renders the proper JSON-LD for a user" do
      expect(response_json).to include(
        "@context" => "http://schema.org",
        "@type" => "Person",
        "mainEntityOfPage" => {
          "@type" => "WebPage",
          "@id" => URL.user(user)
        },
        "url" => URL.user(user),
        "sameAs" => [
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
        ],
        "image" => ProfileImage.new(user).get(width: 320),
        "name" => user.name,
        "email" => user.email,
        "jobTitle" => user.employment_title,
        "description" => user.summary,
        "disambiguatingDescription" => [
          user.mostly_work_with,
          user.currently_hacking_on,
          user.currently_learning,
        ],
        "worksFor" => [
          {
            "@type" => "Organization",
            "name" => user.employer_name,
            "url" => user.employer_url
          },
        ],
        "alumniOf" => user.education,
      )
    end
    # rubocop:enable Rspec/ExampleLength
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
