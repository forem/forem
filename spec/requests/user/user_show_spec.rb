require "rails_helper"

RSpec.describe "UserShow" do
  let!(:profile) do
    create(
      :profile,
      :with_DEV_info,
      user: create(:user, :without_profile),
    )
  end
  let(:user) { profile.user }

  let!(:default_subforem) { create(:subforem, domain: "www.example.com") }
  let!(:other_subforem)   { create(:subforem, domain: "other.com") }

  describe "GET /:slug (user)" do
    before do
      FeatureFlag.add(:subscriber_icon)
      FeatureFlag.enable(:subscriber_icon)
    end

    it "returns a 200 status when navigating to the user's page" do
      get user.path
      expect(response).to have_http_status(:ok)
    end

    it "renders the proper JSON-LD for a user" do
      user.setting.update(display_email_on_profile: true)
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
          "http://example.com",
        ],
        "image" => user.profile_image_url_for(length: 320),
        "name" => user.name,
        "email" => user.email,
        "description" => user.tag_line,
      )
    end

    it "includes a subscription icon if user is subscribed" do
      user.add_role("base_subscriber")
      get user.path
      expect(response.body).to include('class="subscription-icon"')
    end

    it "does not include a subscription icon if user is not subscribed" do
      get user.path
      expect(response.body).not_to include('class="subscription-icon"')
    end

    it "does not render a key if no value is given" do
      incomplete_user = create(:user)
      get incomplete_user.path
      text = Nokogiri::HTML(response.body).at('script[type="application/ld+json"]').text
      response_json = JSON.parse(text)
      expect(response_json).not_to include("worksFor")
      expect(response_json.value?(nil)).to be(false)
      expect(response_json.value?("")).to be(false)
    end

    context "when user signed in" do
      before do
        sign_in user
        get user.path
      end

      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end

    context "when user not signed in" do
      before do
        get user.path
      end

      it "does not render json ld" do
        expect(response.body).to include "application/ld+json"
      end
    end

    context "when user not signed in but internal nav triggered" do
      before do
        get "#{user.path}?i=i"
      end

      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end

  describe "GET /users/ID.json" do
    it "404s when user not found" do
      get user_path("NaN", format: "json")
      expect(response).to have_http_status(:not_found)
    end

    context "when user not signed in" do
      it "does not include 'suspended'" do
        get user_path(user, format: "json")
        parsed = response.parsed_body
        expect(parsed.keys).to match_array(%w[id username])
      end
    end

    context "when user **is** signed in **and** trusted" do
      let(:trusted) { create(:user, :trusted) }

      before do
        sign_in trusted

        get user.path
      end

      it "**does** include 'suspended'" do
        get user_path(user, format: "json")
        parsed = response.parsed_body
        expect(parsed.keys).to match_array(%w[id username suspended])
      end
    end
  end

  context "redirect_if_inactive_in_subforem_for_user" do
    context "when user is 'inactive' in the current subforem" do
      before do
        # Ensure user has no pinned stories, no stories, no comments
        user.articles.delete_all
        user.profile_pins.delete_all
        user.comments.delete_all
      end

      after do
        RequestStore.store[:default_subforem_id] = nil
        RequestStore.store[:subforem_id] = nil
      end

      it "redirects to the user's path in the default subforem" do
        get user.path, headers: { "Host" => other_subforem.domain }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(
          URL.url(user.username, default_subforem)
        )
      end
    end

    context "when user has pinned stories, stories, or comments for the subforem" do
      before do
        create(:article, user: user, subforem: other_subforem)
      end

      after do
        RequestStore.store[:default_subforem_id] = nil
        RequestStore.store[:subforem_id] = nil
      end

      it "does not redirect away from the current subforem" do
        get user.path, headers: { "Host" => other_subforem.domain }
        expect(response).to have_http_status(:ok)
        # Or you could also ensure it does *not* redirect:
        expect(response).not_to be_redirect
      end
    end

    context "when the user has pinned stories, stories, or comments for the default subforem" do
      before do
        create(:article, user: user, subforem: default_subforem)
      end

      after do
        RequestStore.store[:default_subforem_id] = nil
        RequestStore.store[:subforem_id] = nil
      end

      it "rediects away from the current subforem" do
        get user.path, headers: { "Host" => other_subforem.domain }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(
          URL.url(user.username, default_subforem)
        )
      end
    end
  end
end
