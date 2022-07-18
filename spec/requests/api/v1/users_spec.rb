require "rails_helper"

RSpec.describe "Api::V0::Users", type: :request do
  let(:api_secret) { create(:api_secret) }
  let(:v1_headers) { { "api-key" => api_secret.secret, "Accept" => "application/vnd.forem.api-v1+json" } }

  describe "GET /api/users/:id" do
    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    let!(:user) do
      create(:user,
             profile_image: "",
             _skip_creating_profile: true,
             profile: create(:profile, summary: "Something something"))
    end

    context "when unauthenticated" do
      it "returns unauthorized" do
        get api_user_path("by_username"),
            params: { url: user.username },
            headers: { "Accept" => "application/vnd.forem.api-v1+json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized" do
        get api_user_path("by_username"),
            params: { url: user.username },
            headers: v1_headers.merge({ "api-key" => "invalid api key" })
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "returns 404 if the user id is not found" do
      get api_user_path("invalid-id")

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if the user username is not found" do
      get api_user_path("by_username"), params: { url: "invalid-username" }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if the user is not registered" do
      user.update_column(:registered, false)
      get api_user_path(user.id)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 200 if the user username is found" do
      get api_user_path("by_username"), params: { url: user.username }
      expect(response).to have_http_status(:ok)
    end

    it "returns unauthenticated if no authentication and the Forem instance is set to private" do
      allow(Settings::UserExperience).to receive(:public).and_return(false)
      get api_user_path("by_username"), params: { url: user.username }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the correct json representation of the user", :aggregate_failures do
      get api_user_path(user.id)

      response_user = response.parsed_body

      expect(response_user["type_of"]).to eq("user")

      %w[id username name twitter_username github_username].each do |attr|
        expect(response_user[attr]).to eq(user.public_send(attr))
      end

      %w[summary website_url location].each do |attr|
        expect(response_user[attr]).to eq(user.profile.public_send(attr))
      end

      expect(response_user["joined_at"]).to eq(user.created_at.strftime("%b %e, %Y"))
      expect(response_user["profile_image"]).to eq(user.profile_image_url_for(length: 320))
    end
  end

  describe "GET /api/users/me" do
    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    context "when unauthenticated" do
      it "returns unauthorized" do
        get me_api_users_path, headers: { "Accept" => "application/vnd.forem.api-v1+json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized" do
        get me_api_users_path, headers: v1_headers.merge({ "api-key" => "invalid api key" })
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      let(:user) { api_secret.user }

      it "returns the correct json representation of the user", :aggregate_failures do
        get me_api_users_path, headers: v1_headers

        expect(response).to have_http_status(:ok)

        response_user = response.parsed_body

        expect(response_user["type_of"]).to eq("user")

        %w[id username name twitter_username github_username].each do |attr|
          expect(response_user[attr]).to eq(user.public_send(attr))
        end

        %w[summary website_url location].each do |attr|
          expect(response_user[attr]).to eq(user.profile.public_send(attr))
        end

        expect(response_user["joined_at"]).to eq(user.created_at.strftime("%b %e, %Y"))
        expect(response_user["profile_image"]).to eq(user.profile_image_url_for(length: 320))
      end

      it "returns 200 if no authentication and the Forem instance is set to private but user is authenticated" do
        allow(Settings::UserExperience).to receive(:public).and_return(false)
        get me_api_users_path, headers: v1_headers

        response_user = response.parsed_body

        expect(response_user["type_of"]).to eq("user")

        %w[id username name twitter_username github_username].each do |attr|
          expect(response_user[attr]).to eq(user.public_send(attr))
        end

        %w[summary website_url location].each do |attr|
          expect(response_user[attr]).to eq(user.profile.public_send(attr))
        end

        expect(response_user["joined_at"]).to eq(user.created_at.strftime("%b %e, %Y"))
        expect(response_user["profile_image"]).to eq(user.profile_image_url_for(length: 320))
      end
    end
  end

  describe "PUT /api/users/:id/suspend" do
    let(:target_user) { create(:user) }
    let(:payload) { { note: "Violated CoC despite multiple warnings" } }

    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    context "when unauthenticated" do
      it "returns unauthorized" do
        put api_user_suspend_path(id: target_user.id),
            params: payload,
            headers: { "Accept" => "application/vnd.forem.api-v1+json" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized if api key is invalid" do
        put api_user_suspend_path(id: target_user.id),
            params: payload,
            headers: v1_headers.merge({ "api-key" => "invalid api key" })

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns unauthorized if api key belongs to non-admin user" do
        put api_user_suspend_path(id: target_user.id),
            params: payload,
            headers: v1_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      it "is successful in suspending a user", :aggregate_failures do
        api_secret.user.add_role(:super_admin)

        expect do
          put api_user_suspend_path(id: target_user.id),
              params: payload,
              headers: v1_headers

          expect(response).to have_http_status(:ok)
          expect(target_user.reload.suspended?).to be true
          expect(Note.last.content).to eq(payload[:note])
        end.to change(Note, :count).by(1)
      end
    end
  end

  describe "PUT /api/users/:id/unpublish" do
    let(:target_user) { create(:user) }

    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    context "when unauthenticated" do
      it "returns unauthorized" do
        put api_user_unpublish_path(id: target_user.id),
            headers: { "Accept" => "application/vnd.forem.api-v1+json" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized if api key is invalid" do
        put api_user_unpublish_path(id: target_user.id),
            headers: v1_headers.merge({ "api-key" => "invalid api key" })

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns unauthorized if api key belongs to non-admin user" do
        put api_user_unpublish_path(id: target_user.id),
            headers: v1_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      it "is successful in unpublishing a user's comments and articles", :aggregate_failures do
        allow(Moderator::UnpublishAllArticlesWorker).to receive(:perform_async)
        api_secret.user.add_role(:super_admin)
        put api_user_unpublish_path(id: target_user.id),
            headers: v1_headers

        expect(response).to have_http_status(:ok)
        expect(Moderator::UnpublishAllArticlesWorker).to have_received(:perform_async).with(target_user.id).once
      end
    end
  end
end
