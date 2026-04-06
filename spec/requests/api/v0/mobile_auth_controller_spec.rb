require "rails_helper"

RSpec.describe "Api::V0::MobileAuth", type: :request do
  let(:user) { create(:user) }
  let(:valid_jwt) { "mock.jwt.token" }

  before do
    allow(JWT).to receive(:encode).and_return(valid_jwt)
    allow(::Authentication::Authenticator).to receive(:call).and_return(user)
    
    allow(Settings::Authentication).to receive(:google_oauth2_key).and_return("google_client_id")
    allow(Settings::Authentication).to receive(:github_key).and_return("github_client_id")
    allow(Settings::Authentication).to receive(:facebook_key).and_return("fb_app_id")
    allow(Settings::Authentication).to receive(:facebook_secret).and_return("fb_secret")
    allow(Settings::Authentication).to receive(:twitter_key).and_return("twitter_key")
    allow(Settings::Authentication).to receive(:twitter_secret).and_return("twitter_secret")
  end

  describe "POST /api/auth/mobile_exchange" do
    context "with unsupported provider" do
      it "returns a bad request error" do
        post "/api/auth/mobile_exchange", params: { provider: "unsupported", access_token: "abcd" }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Unsupported auth provider")
      end
    end

    describe "Google OAuth" do
      context "with a valid token intended for Forem" do
        before do
          stub_request(:get, "https://oauth2.googleapis.com/tokeninfo?access_token=valid_token")
            .to_return(status: 200, body: { email: user.email, sub: "12345", aud: "google_client_id" }.to_json)
        end

        it "authenticates the user successfully" do
          post "/api/auth/mobile_exchange", params: { provider: "google_oauth2", access_token: "valid_token" }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["jwt"]).to eq(valid_jwt)
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
          expect(JSON.parse(response.body)["error"]).to eq("Token verification failed")
        end
      end
    end

    describe "GitHub OAuth" do
      context "with a valid token intended for Forem" do
        before do
          stub_request(:get, "https://api.github.com/user")
            .with(headers: { 'Authorization' => 'token valid_token' })
            .to_return(
              status: 200, 
              headers: { "X-OAuth-Client-Id" => "github_client_id" }, 
              body: { id: 67890, email: user.email }.to_json
            )
        end

        it "authenticates successfully" do
          post "/api/auth/mobile_exchange", params: { provider: "github", access_token: "valid_token" }
          expect(response).to have_http_status(:ok)
        end
      end

      context "with a Confused Deputy (token from another app)" do
        before do
          stub_request(:get, "https://api.github.com/user")
            .with(headers: { 'Authorization' => 'token hijacked_token' })
            .to_return(
              status: 200, 
              headers: { "X-OAuth-Client-Id" => "malicious_github_oauth_id" }, 
              body: { id: 67890, email: user.email }.to_json
            )
        end

        it "fails safely with 401" do
          post "/api/auth/mobile_exchange", params: { provider: "github", access_token: "hijacked_token" }
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    describe "Facebook OAuth" do
      context "with a valid token intended for Forem" do
        before do
          # Debug Token validates app_id matches Forem
          stub_request(:get, "https://graph.facebook.com/debug_token?access_token=fb_app_id%7Cfb_secret&input_token=valid_token")
            .to_return(status: 200, body: { data: { app_id: "fb_app_id", is_valid: true } }.to_json)
            
          # Next step fetches the user profile
          stub_request(:get, "https://graph.facebook.com/me?access_token=valid_token&fields=id,email")
            .to_return(status: 200, body: { id: "55555", email: user.email }.to_json)
        end

        it "authenticates the user successfully" do
          post "/api/auth/mobile_exchange", params: { provider: "facebook", access_token: "valid_token" }
          expect(response).to have_http_status(:ok)
        end
      end

      context "with a Confused Deputy (token intended for a malicious app)" do
        before do
          # Debug Token reveals it belongs to malicious_app_id
          stub_request(:get, "https://graph.facebook.com/debug_token?access_token=fb_app_id%7Cfb_secret&input_token=hijacked_token")
            .to_return(status: 200, body: { data: { app_id: "malicious_app_id", is_valid: true } }.to_json)
        end

        it "blocks the login before even fetching the user profile" do
          post "/api/auth/mobile_exchange", params: { provider: "facebook", access_token: "hijacked_token" }
          expect(response).to have_http_status(:unauthorized)
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
      
      # Twitter is inherently protected from confused deputy because we exchange an authorization code
      # using our exact Server-side Client Secret. If it was from another app, the exchange would fail upstream 401.
    end
  end
end
