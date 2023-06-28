require "rails_helper"

RSpec.describe "FollowingsController" do
  let(:user) { create(:user) }

  describe "GET /followings/users" do
    let(:followed) { create(:user) }

    before do
      user.follow(followed)

      user.reload
    end

    context "when user is unauthorized" do
      it "returns unauthorized" do
        get followings_users_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authorized" do
      before do
        sign_in user
      end

      it "returns user's followings list with the correct format" do
        get followings_users_path
        expect(response).to have_http_status(:ok)

        response_following = response.parsed_body.first
        expect(response_following["type_of"]).to eq("user_following")
        expect(response_following["id"]).to eq(user.follows.last.id)
        expect(response_following["name"]).to eq(followed.name)
        expect(response_following["path"]).to eq(followed.path)
        expect(response_following["username"]).to eq(followed.username)
        expect(response_following["profile_image"]).to eq(followed.profile_image_url_for(length: 60))
      end
    end
  end

  describe "GET /followings/tags" do
    let(:followed) { create(:tag) }

    before do
      user.follow(followed)

      user.reload
    end

    context "when user is unauthorized" do
      it "returns unauthorized" do
        get followings_tags_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authorized" do
      before do
        sign_in user
      end

      it "returns user's followings list with the correct format" do
        get followings_tags_path
        expect(response).to have_http_status(:ok)

        follow = user.follows.last
        response_following = response.parsed_body.first

        expect(response_following["type_of"]).to eq("tag_following")
        expect(response_following["id"]).to eq(follow.id)
        expect(response_following["name"]).to eq(followed.name)
        expect(response_following["points"]).to eq(follow.points)
        expect(response_following["token"]).to be_present
        expect(response_following["color"]).to eq("#000000")
      end
    end
  end

  describe "GET /followings/organizations" do
    let(:followed) { create(:organization) }

    before do
      user.follow(followed)

      user.reload
    end

    context "when user is unauthorized" do
      it "returns unauthorized" do
        get followings_organizations_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authorized" do
      before do
        sign_in user
      end

      it "returns user's followings list with the correct format" do
        get followings_organizations_path
        expect(response).to have_http_status(:ok)

        response_following = response.parsed_body.first
        expect(response_following["type_of"]).to eq("organization_following")
        expect(response_following["id"]).to eq(user.follows.last.id)
        expect(response_following["name"]).to eq(followed.name)
        expect(response_following["path"]).to eq(followed.path)
        expect(response_following["username"]).to eq(followed.username)
        expect(response_following["profile_image"]).to eq(followed.profile_image_url_for(length: 60))
      end
    end
  end

  describe "GET /followings/podcasts" do
    let(:followed) { create(:podcast) }

    before do
      user.follow(followed)

      user.reload
    end

    context "when user is unauthorized" do
      it "returns unauthorized" do
        get followings_podcasts_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authorized" do
      before do
        sign_in user
      end

      it "returns user's followings list with the correct format" do
        get followings_podcasts_path
        expect(response).to have_http_status(:ok)

        response_following = response.parsed_body.first
        expect(response_following["type_of"]).to eq("podcast_following")
        expect(response_following["id"]).to eq(user.follows.last.id)
        expect(response_following["name"]).to eq(followed.name)
        expect(response_following["path"]).to eq("/#{followed.path}")
        expect(response_following["username"]).to eq(followed.name)
        expect(response_following["profile_image"]).to eq(followed.profile_image_url_for(length: 60))
      end
    end
  end
end
