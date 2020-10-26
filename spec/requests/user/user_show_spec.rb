require "rails_helper"

RSpec.describe "UserShow", type: :request do
  let(:user) { create(:user, :with_all_info, email_public: true) }

  describe "GET /:slug (user)" do
    it "returns a 200 status when navigating to the user's page" do
      get user.path
      expect(response).to have_http_status(:ok)
    end

    # rubocop:disable RSpec/ExampleLength
    it "renders the proper JSON-LD for a user" do
      get user.path
      text = Nokogiri::HTML(response.body).at('script[type="application/ld+json"]').text
      response_json = JSON.parse(text)
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
          user.website_url,
        ],
        "image" => Images::Profile.call(user.profile_image_url, length: 320),
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
    # rubocop:enable RSpec/ExampleLength

    it "does not render a key if no value is given" do
      incomplete_user = create(:user)
      get incomplete_user.path
      text = Nokogiri::HTML(response.body).at('script[type="application/ld+json"]').text
      response_json = JSON.parse(text)
      expect(response_json).not_to include("worksFor")
      expect(response_json.value?(nil)).to be(false)
      expect(response_json.value?("")).to be(false)
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
      get "#{user.path}?i=i"
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end
end
