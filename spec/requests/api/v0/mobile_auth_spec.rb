require "rails_helper"

RSpec.describe "Api::V0::MobileAuth", type: :request do
  let(:valid_access_token) { 'ya29.valid_token_string' }
  let(:invalid_access_token) { 'ya29.invalid_token_string' }
  let(:user) { create(:user) }
  let(:valid_jwt) { "mock.jwt.token" }

  before do
    allow(JWT).to receive(:encode).and_return(valid_jwt)
    allow(::Authentication::Authenticator).to receive(:call).and_return(user)
    
    allow(Settings::Authentication).to receive(:google_oauth2_key).and_return("google_client_id")
    allow(Settings::Authentication).to receive(:github_key).and_return("github_client_id")
    allow(Settings::Authentication).to receive(:github_secret).and_return("github_secret")
    allow(Settings::Authentication).to receive(:facebook_key).and_return("fb_app_id")
    allow(Settings::Authentication).to receive(:facebook_secret).and_return("fb_secret")
    allow(Settings::Authentication).to receive(:twitter_key).and_return("twitter_key")
    allow(Settings::Authentication).to receive(:twitter_secret).and_return("twitter_secret")
    allow(Settings::Authentication).to receive(:mlh_key).and_return("mock_mlh_key")
    allow(Settings::Authentication).to receive(:mlh_secret).and_return("mock_mlh_secret")
  end

  describe "POST /api/auth/mobile_exchange" do
    context "with an unsupported provider" do
      it "returns a bad request error" do
        post "/api/auth/mobile_exchange", params: { provider: "apple", access_token: "abcd" }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Unsupported auth provider")
      end
    end

    describe "Google OAuth" do
      context "with a valid token intended for Forem" do
        before do
          stub_request(:get, "https://oauth2.googleapis.com/tokeninfo?access_token=#{valid_access_token}")
            .to_return(status: 200, body: { email: user.email, sub: "12345", aud: "google_client_id" }.to_json)
        end

        it "authenticates the user successfully and issues an aligned jwt cookie" do
          post "/api/auth/mobile_exchange", params: { provider: "google_oauth2", access_token: valid_access_token }
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["jwt"]).to eq(valid_jwt)
          
          # Assert cookie is present and attributes are properly set (httponly)
          jwt_cookie_header = response.headers["Set-Cookie"]
          expect(jwt_cookie_header).to be_present
          expect(jwt_cookie_header).to match(/jwt=mock\.jwt\.token/)
          expect(jwt_cookie_header).to match(/HttpOnly/i)
        end

        context "when the user has never signed in before (current_sign_in_at is blank)" do
          before do
            user.update_column(:current_sign_in_at, nil)
          end

          it "updates current_sign_in_at to the current time" do
            post "/api/auth/mobile_exchange", params: { provider: "google_oauth2", access_token: valid_access_token }
            expect(user.reload.current_sign_in_at).to be_within(5.seconds).of(Time.current)
          end
        end

        context "when the user has previously signed in (current_sign_in_at is present)" do
          let(:previous_time) { 1.day.ago.change(usec: 0) }

          before do
            user.update_column(:current_sign_in_at, previous_time)
          end

          it "updates current_sign_in_at to the current time" do
            post "/api/auth/mobile_exchange", params: { provider: "google_oauth2", access_token: valid_access_token }
            expect(user.reload.current_sign_in_at).not_to eq(previous_time)
            expect(user.current_sign_in_at).to be_within(5.seconds).of(Time.current)
          end
        end
      end

      context "with a Confused Deputy (token intended for a malicious app)" do
        before do
          stub_request(:get, "https://oauth2.googleapis.com/tokeninfo?access_token=hijacked_token")
            .to_return(status: 200, body: { email: user.email, sub: "12345", aud: "malicious_app_id" }.to_json)
        end

        it "blocks the login with a 401 Unauthorized" do
          post "/api/auth/mobile_exchange", params: { provider: "google_oauth2", access_token: "hijacked_token" }
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Token audience mismatch")
        end
      end

      context "with an invalid access token" do
        before do
          stub_request(:get, "https://oauth2.googleapis.com/tokeninfo?access_token=#{invalid_access_token}")
            .to_return(status: 400, body: { error: "invalid_token" }.to_json)
        end

        it "returns unauthorized" do
          post "/api/auth/mobile_exchange", params: { provider: "google_oauth2", access_token: invalid_access_token }
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Invalid access token")
        end
      end
    end

    describe "GitHub OAuth" do
      context "with a valid token intended for Forem" do
        before do
          basic_auth_header = "Basic #{Base64.strict_encode64("github_client_id:github_secret")}"
          stub_request(:post, "https://api.github.com/applications/github_client_id/token")
            .with(
              body: { access_token: valid_access_token }.to_json,
              headers: { 'Authorization' => basic_auth_header }
            )
            .to_return(status: 200, body: {}.to_json)
            
          stub_request(:get, "https://api.github.com/user")
            .with(headers: { 'Authorization' => "token #{valid_access_token}" })
            .to_return(status: 200, body: { id: 67890, email: user.email }.to_json)
        end

        it "authenticates successfully" do
          post "/api/auth/mobile_exchange", params: { provider: "github", access_token: valid_access_token }
          expect(response).to have_http_status(:ok)
        end
      end

      context "with a Confused Deputy (token from another app)" do
        before do
          basic_auth_header = "Basic #{Base64.strict_encode64("github_client_id:github_secret")}"
          stub_request(:post, "https://api.github.com/applications/github_client_id/token")
            .with(
              body: { access_token: "hijacked_token" }.to_json,
              headers: { 'Authorization' => basic_auth_header }
            )
            .to_return(status: 404, body: {}.to_json)
        end

        it "fails safely with 401" do
          post "/api/auth/mobile_exchange", params: { provider: "github", access_token: "hijacked_token" }
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Token invalid or audience mismatch")
        end
      end
    end

    describe "Facebook OAuth" do
      context "with a valid token intended for Forem" do
        before do
          stub_request(:get, "https://graph.facebook.com/debug_token")
            .with(query: hash_including("access_token" => "fb_app_id|fb_secret", "input_token" => valid_access_token))
            .to_return(status: 200, body: { data: { app_id: "fb_app_id", is_valid: true } }.to_json)
            
          stub_request(:get, "https://graph.facebook.com/me")
            .with(query: hash_including("access_token" => valid_access_token))
            .to_return(status: 200, body: { id: "55555", email: user.email }.to_json)
        end

        it "authenticates the user successfully" do
          post "/api/auth/mobile_exchange", params: { provider: "facebook", access_token: valid_access_token }
          expect(response).to have_http_status(:ok)
        end
      end

      context "with a Confused Deputy (token intended for a malicious app)" do
        before do
          stub_request(:get, "https://graph.facebook.com/debug_token")
            .with(query: hash_including("access_token" => "fb_app_id|fb_secret", "input_token" => "hijacked_token"))
            .to_return(status: 200, body: { data: { app_id: "malicious_app_id", is_valid: true } }.to_json)
        end

        it "blocks the login before even fetching the user profile" do
          post "/api/auth/mobile_exchange", params: { provider: "facebook", access_token: "hijacked_token" }
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Token audience mismatch")
        end
      end
    end

    describe "Twitter2 PKCE Auth Code Flow" do
      context "with a valid code" do
        before do
          stub_request(:post, "https://api.twitter.com/2/oauth2/token")
            .to_return(status: 200, body: { access_token: "exchanged_twitter_token" }.to_json)
            
          stub_request(:get, "https://api.twitter.com/2/users/me?user.fields=profile_image_url")
            .with(headers: { 'Authorization' => 'Bearer exchanged_twitter_token' })
            .to_return(status: 200, body: { data: { id: 11111, email: user.email } }.to_json)
        end

        it "authenticates successfully" do
          post "/api/auth/mobile_exchange", params: { provider: "twitter2", access_token: "auth_code", code_verifier: "xyz" }
          expect(response).to have_http_status(:ok)
        end
      end
    end
    
    describe "MLH Auth Code Flow" do
      context "with a valid code" do
        before do
          stub_request(:post, "https://my.mlh.io/oauth/token")
            .to_return(status: 200, body: { "access_token" => "mlh_mock_token" }.to_json, headers: { 'Content-Type' => 'application/json' })
            
          stub_request(:get, "https://my.mlh.io/api/v3/user.json?access_token=mlh_mock_token")
            .to_return(status: 200, body: { "status" => "OK", "data" => { "email" => user.email, "id" => 123 } }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it "authenticates successfully" do
          post "/api/auth/mobile_exchange", params: { provider: "mlh", access_token: "valid_code" }
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
