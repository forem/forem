require "rails_helper"

RSpec.describe "Users", type: :request do
  RSpec.shared_examples "a default suggested_users request" do |path|
    let(:suggested_users_list) { %w[eeyore] }
    let!(:suggested_user) { create(:user, name: "Eeyore", username: "eeyore", summary: "I am always sad :(") }

    before do
      allow(SiteConfig).to receive(:suggested_users).and_return(suggested_users_list)
    end

    it "returns the default suggested_users from SiteConfig if they are present" do
      get path

      expect(response).to have_http_status(:ok)

      response_user = response.parsed_body.first
      expect(response_user["id"]).to eq(suggested_user.id)
      expect(response_user["name"]).to eq(suggested_user.name)
      expect(response_user["username"]).to eq(suggested_user.username)
      expect(response_user["summary"]).to eq(suggested_user.summary)
      expect(response_user["profile_image_url"]).to eq(ProfileImage.new(suggested_user).get(width: 90))
      expect(response_user["following"]).to be(false)
    end
  end

  describe "GET /users" do
    let(:user) { create(:user) }

    context "when the user is not signed in" do
      it_behaves_like "a default suggested_users request", "/users"
    end

    context "when no state params are present" do
      before { sign_in user }

      it "returns default suggested_users from SiteConfig if they are present" do
        get users_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to be_empty
      end
    end

    context "when follow_suggestions params are present and no suggestions are found" do
      let(:my_instance) { instance_double(Suggester::Users::Recent) }

      before do
        allow(Suggester::Users::Recent).to receive(:new).and_return(my_instance)
        allow(my_instance).to receive(:suggest).and_return([])
      end

      it_behaves_like "a default suggested_users request", "/users"
    end

    context "when follow_suggestions params are present" do
      it "returns follow suggestions for an authenticated user" do
        user = create(:user)
        tag = create(:tag)
        user.follow(tag)

        other_user = create(:user)
        create(:article, user: other_user, tags: [tag.name])

        sign_in user

        get users_path(state: "follow_suggestions")

        response_user = response.parsed_body.first
        expect(response_user["id"]).to eq(other_user.id)
      end

      it "returns follow suggestions that have profile images" do
        user = create(:user)
        tag = create(:tag)
        user.follow(tag)

        other_user = create(:user)
        create(:article, user: other_user, tags: [tag.name])

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
