require "rails_helper"

RSpec.describe "Users" do
  describe "GET /users" do
    let(:user) { create(:user, username: "Sloan") }

    context "when no state params are present" do
      it "returns no users" do
        sign_in user
        get users_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to be_empty
      end
    end

    context "when follow_suggestions params are present and no suggestions are found" do
      it "returns an empty array (no automated suggested follow)" do
        sign_in user

        get users_path(state: "follow_suggestions")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
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
