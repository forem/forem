require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /users" do
    let(:user) { create(:user, username: "Sloan") }
    let!(:suggested_users_list) { %w[eeyore] }
    let!(:suggested_user_profile) do
      create(
        :profile,
        user: create(:user, :without_profile, username: "eeyore", name: "Eeyore"),
        summary: "I am always sad",
      )
    end
    let!(:suggested_user) { suggested_user_profile.user }

    before do
      allow(SiteConfig).to receive(:suggested_users).and_return(suggested_users_list)
    end

    context "when no state params are present" do
      it "returns no users" do
        sign_in user
        get users_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to be_empty
      end
    end

    context "when follow_suggestions params are present and no suggestions are found" do
      it "returns the default suggested_users from SiteConfig if they are present" do
        sign_in user

        get users_path(state: "follow_suggestions")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.first).to include(
          "id" => suggested_user.id,
          "name" => suggested_user.name,
          "username" => suggested_user.username,
          "summary" => suggested_user.summary,
          "profile_image_url" => Images::Profile.call(suggested_user.profile_image_url, length: 90),
          "following" => false,
        )
      end
    end

    context "when follow_suggestions params are present" do
      let(:user) { create(:user) }
      let(:tag) { create(:tag) }
      let(:other_user) { create(:user) }

      before do
        # Prepare auto-generated user suggestions
        user.follow(tag)
        create(:article, user: other_user, tags: [tag.name])
      end

      it "returns follow suggestions for an authenticated user" do
        sign_in user

        get users_path(state: "follow_suggestions")

        response_user = response.parsed_body.first
        expect(response_user["id"]).to eq(other_user.id)
      end

      it "returns follow suggestions that have profile images" do
        sign_in user

        get users_path(state: "follow_suggestions")

        response_user = response.parsed_body.first
        expect(response_user["profile_image_url"]).to eq(other_user.profile_image_url)
      end

      it "returns the default suggested_users from SiteConfig if prefer_manual_suggested_users is true" do
        allow(SiteConfig).to receive(:prefer_manual_suggested_users).and_return(true)

        sign_in user

        get users_path(state: "follow_suggestions")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.first).to include(
          "id" => suggested_user.id,
          "name" => suggested_user.name,
          "username" => suggested_user.username,
          "summary" => suggested_user.summary,
          "profile_image_url" => Images::Profile.call(suggested_user.profile_image_url, length: 90),
          "following" => false,
        )
      end
    end

    context "when sidebar_suggestions params are present" do
      it "returns no sidebar suggestions for an authenticated user" do
        sign_in create(:user)

        get users_path(state: "sidebar_suggestions")

        expect(response.parsed_body).to be_empty
      end
    end
  end
end
