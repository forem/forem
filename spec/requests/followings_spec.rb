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
    context "when user is unauthorized" do
      let(:followed) { create(:tag) }

      before do
        user.follow(followed)
        user.reload
      end

      it "returns unauthorized" do
        get followings_tags_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authorized" do
      let(:first_followed_tag) { create(:tag, name: "tagone") }
      let(:antifollowed_tag) { create(:tag, name: "tagtwo") }
      let(:second_followed_tag) { create(:tag, name: "tagthree") }

      before do
        sign_in user
        first_followed = user.follow(first_followed_tag)
        first_followed.update explicit_points: 5

        antifollowed = user.follow(antifollowed_tag)
        antifollowed.update explicit_points: -5

        second_followed = user.follow(second_followed_tag)
        second_followed.update explicit_points: 0
        user.reload
      end

      it "returns the user's followings tag list" do
        get followings_tags_path, params: { controller_action: "following_tags" }
        expect(response).to have_http_status(:ok)

        expect(response.parsed_body.count).to eq(2)
        expect(response.parsed_body.pluck("name")).to eq(%w[tagone tagthree])
      end

      it "returns the user's hidden tag list" do
        get followings_tags_path, params: { controller_action: "hidden_tags" }
        expect(response).to have_http_status(:ok)

        expect(response.parsed_body.count).to eq(1)
        expect(response.parsed_body.pluck("name")).to eq(%w[tagtwo])
      end

      it "returns a list with the correct format" do
        get followings_tags_path
        expect(response).to have_http_status(:ok)

        followed_object = user.follows.detect { |obj| obj["followable_id"] == first_followed_tag.id }
        followed_object_response = response.parsed_body.detect { |obj| obj["name"] == "tagone" }

        expect(followed_object_response["type_of"]).to eq("tag_following")
        expect(followed_object_response["id"]).to eq(followed_object.id)
        expect(followed_object_response["name"]).to eq(first_followed_tag.name)
        expect(followed_object_response["points"]).to eq(followed_object.points)
        expect(followed_object_response["explicit_points"]).to eq(followed_object.explicit_points)
        expect(followed_object_response["token"]).to be_present
        expect(followed_object_response["color"]).to eq("#000000")
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
