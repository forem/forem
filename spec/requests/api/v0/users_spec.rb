require "rails_helper"

RSpec.describe "Api::V0::Users" do
  describe "GET /api/users/:id" do
    let!(:user) do
      create(:user,
             profile_image: "",
             _skip_creating_profile: true,
             profile: create(:profile, summary: "Something something"))
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

    it "hydrates joined profile attributes without querying profiles again" do
      queries = []
      callback = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get api_user_path(user.id)
      end

      expect(response).to have_http_status(:ok)
      expect(queries.grep(/FROM "profiles"/i)).to be_empty
      expect(queries.grep(/FROM "users_settings"/i)).to be_empty
    end

    it "matches Jbuilder byte-for-byte via ForemNative under UTC and falls back cleanly", :aggregate_failures do
      user.update!(name: "Ada <Lovelace> & Co.", created_at: Time.utc(2026, 1, 5, 8, 30, 0))
      user.profile.update!(summary: "Line 1\nLine 2 🚀")

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TZ").and_return("Etc/UTC")

      Time.use_zone("UTC") do
        native_results = []
        allow(ForemNative).to receive(:serialize_api_user_json).and_wrap_original do |method, *args, **kwargs|
          method.call(*args, **kwargs).tap { |res| native_results << res }
        end

        get api_user_path(user.id)
        expect(response).to have_http_status(:ok)
        native_body = response.body
        native_media_type = response.media_type
        expect(native_results.length).to eq(1)
        expect(native_results.first).to be_a(String)

        allow(ForemNative).to receive(:serialize_api_user_json).and_return(nil)
        get api_user_path(user.id)
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(native_media_type)
        expect(native_body).to eq(response.body)
      end
    end

    it "skips native serialization when HTML entity escaping is disabled" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TZ").and_return("Etc/UTC")
      allow(ActiveSupport::JSON::Encoding).to receive(:escape_html_entities_in_json).and_return(false)
      allow(ForemNative).to receive(:serialize_api_user_json).and_call_original

      Time.use_zone("UTC") { get api_user_path(user.id) }

      expect(response).to have_http_status(:ok)
      expect(ForemNative).not_to have_received(:serialize_api_user_json)
    end

    it "skips native serialization under a non-UTC time zone" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TZ").and_return("America/New_York")
      allow(ForemNative).to receive(:serialize_api_user_json).and_call_original

      Time.use_zone("America/New_York") { get api_user_path(user.id) }

      expect(response).to have_http_status(:ok)
      expect(ForemNative).not_to have_received(:serialize_api_user_json)
    end
  end

  describe "GET /api/users/me" do
    it "requires request to be authenticated" do
      get me_api_users_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "when request is authenticated" do
      let(:user) { create(:user) }
      let(:api_secret) { create(:api_secret, user: user) }
      let(:headers) { { "api-key" => api_secret.secret } }

      it "returns the correct json representation of the user", :aggregate_failures do
        get me_api_users_path, headers: headers

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
        get me_api_users_path, headers: headers

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

      it "matches Jbuilder byte-for-byte via ForemNative under UTC", :aggregate_failures do
        user.update!(name: "Grace <Hopper> & Co.", created_at: Time.utc(2026, 1, 5, 8, 30, 0))
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TZ").and_return("Etc/UTC")

        Time.use_zone("UTC") do
          native_results = []
          allow(ForemNative).to receive(:serialize_api_user_json).and_wrap_original do |method, *args, **kwargs|
            method.call(*args, **kwargs).tap { |res| native_results << res }
          end

          get me_api_users_path, headers: headers
          native_body = response.body
          expect(native_results.length).to eq(1)
          expect(native_results.first).to be_a(String)

          allow(ForemNative).to receive(:serialize_api_user_json).and_return(nil)
          get me_api_users_path, headers: headers
          expect(native_body).to eq(response.body)
        end
      end
    end
  end
end
