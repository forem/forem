# spec/requests/auth_pass_spec.rb
require 'rails_helper'

RSpec.describe "AuthPassController", type: :request do
  let(:user) { create(:user) }

  # Helper method to generate a valid token
  def generate_auth_token(user)
    Authentication::AuthToken.encode_auth_pass(user)
  end

  # Helper method to generate an expired token
  def generate_expired_auth_token(user)
    payload = {
      user_id: user.id,
      exp: 5.minutes.ago.to_i,
      iat: 10.minutes.ago.to_i,
      jti: SecureRandom.uuid,
      purpose: Authentication::AuthToken::AUTH_PASS_PURPOSE,
      salt: Authentication::AuthToken.salt_fingerprint(user)
    }
    secret = Rails.application.key_generator.generate_key(Authentication::AuthToken::AUTH_PASS_KEY_SALT, 32)
    JWT.encode(payload, secret, "HS256")
  end

  # Helper method to parse JSON responses
  def json_response
    JSON.parse(response.body)
  end

  # Simulate cross-origin requests by setting the Origin header
  let(:allowed_origin) { "the-other-domain.com" }
  let!(:subforem) { create(:subforem, domain: allowed_origin) }

  describe "POST /auth_pass/token_login" do
    before do
      @headers = {
        'Origin' => allowed_origin,
        'Content-Type' => 'application/json'
      }
    end
  
    context "with a valid token and allowed origin" do
      it "authenticates the user, sets the remember_user_token cookie, and returns success: true" do
        token = generate_auth_token(user)
  
        post '/auth_pass/token_login', params: { token: token }.to_json, headers: @headers
  
        expect(response).to have_http_status(:ok)
        expect(response.headers["Cache-Control"]).to include("no-store")
        expect(response.content_type).to include("application/json")
        expect(json_response['success']).to be true
        expect(response.headers['Access-Control-Allow-Origin']).to eq(allowed_origin)
        expect(response.headers['Access-Control-Allow-Credentials']).to eq('true')
  
        # Verify the remember_user_token cookie is set
        cookie = response.cookies['remember_user_token']
        expect(cookie).not_to be_nil
  
        # Decode the value of the cookie to verify its structure
        cookie_parts = cookie.split('--')
        expect(cookie_parts.size).to eq(2)
      end
    end
  
    context "with an invalid token" do
      it "returns success: false with 'Invalid or expired token' error" do
        post '/auth_pass/token_login', params: { token: 'invalid_token' }.to_json, headers: @headers
  
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Invalid or expired token')
      end
    end
  
    context "with an expired token" do
      it "returns success: false with 'Invalid or expired token' error" do
        token = generate_expired_auth_token(user)
  
        post '/auth_pass/token_login', params: { token: token }.to_json, headers: @headers
  
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Invalid or expired token')
      end
    end
  
    context "with an unauthorized origin" do
      it "does not set CORS headers and returns status ok" do
        token = generate_auth_token(user)
        unauthorized_headers = @headers.merge('Origin' => 'https://unauthorized-domain.com')
  
        post '/auth_pass/token_login', params: { token: token }.to_json, headers: unauthorized_headers
  
        expect(response.headers['Access-Control-Allow-Origin']).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end

    context "with a mobile API token" do
      it "rejects a 30-day mobile JWT signed with secret_key_base" do
        mobile_token = Authentication::AuthToken.encode_mobile_api(user)

        post "/auth_pass/token_login", params: { token: mobile_token }.to_json, headers: @headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["success"]).to be false
        expect(response.cookies["remember_user_token"]).to be_nil
      end

      it "rejects a legacy unpurposed JWT signed with secret_key_base" do
        legacy_token = JWT.encode({ user_id: user.id, exp: 30.days.from_now.to_i }, Rails.application.secret_key_base)

        post "/auth_pass/token_login", params: { token: legacy_token }.to_json, headers: @headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["success"]).to be false
        expect(response.cookies["remember_user_token"]).to be_nil
      end
    end

    context "when replaying an already-used auth_pass token" do
      let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
      end

      it "accepts the token once and rejects subsequent replays" do
        token = generate_auth_token(user)

        post "/auth_pass/token_login", params: { token: token }.to_json, headers: @headers
        expect(response).to have_http_status(:ok)

        post "/auth_pass/token_login", params: { token: token }.to_json, headers: @headers
        expect(response).to have_http_status(:unauthorized)
        expect(json_response["success"]).to be false
      end
    end

    context "when the user changes their password after token issuance" do
      it "rejects the previously issued token" do
        token = generate_auth_token(user)
        user.update!(password: "NewSecurePassword123!", password_confirmation: "NewSecurePassword123!")

        post "/auth_pass/token_login", params: { token: token }.to_json, headers: @headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["success"]).to be false
        expect(response.cookies["remember_user_token"]).to be_nil
      end
    end

    context "when the user signs out after token issuance" do
      let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
      end

      it "rejects the previously issued token even if current_sign_in_at is later restored" do
        token = generate_auth_token(user)
        Authentication::AuthToken.revoke_for_user!(user.id)
        user.update_columns(current_sign_in_at: Time.current)

        post "/auth_pass/token_login", params: { token: token }.to_json, headers: @headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["success"]).to be false
        expect(response.cookies["remember_user_token"]).to be_nil
      end
    end

    context "when the user account is locked" do
      it "rejects the token" do
        token = generate_auth_token(user)
        user.update_column(:locked_at, Time.current)

        post "/auth_pass/token_login", params: { token: token }.to_json, headers: @headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["success"]).to be false
        expect(response.cookies["remember_user_token"]).to be_nil
      end
    end

    context "with an oversized exp claim on an auth_pass token" do
      it "rejects tokens exceeding the 5-minute TTL bound" do
        now = Time.current.to_i
        secret = Rails.application.key_generator.generate_key(Authentication::AuthToken::AUTH_PASS_KEY_SALT, 32)
        oversized_token = JWT.encode(
          {
            user_id: user.id,
            exp: now + 30.days.to_i,
            iat: now,
            jti: SecureRandom.uuid,
            purpose: Authentication::AuthToken::AUTH_PASS_PURPOSE,
            salt: Authentication::AuthToken.salt_fingerprint(user)
          },
          secret,
          "HS256",
        )

        post "/auth_pass/token_login", params: { token: oversized_token }.to_json, headers: @headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["success"]).to be false
      end
    end
  end

  describe "GET /auth_pass/iframe" do
    before do
      allow(Settings::General).to receive(:app_domain).and_return("forem.com")
    end

    context "when requested on an unauthorized host" do
      it "returns 401 unauthorized" do
        host! "unauthorized-domain.com"
        get "/auth_pass/iframe"

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to eq("Unauthorized")
      end
    end

    context "when user is signed in" do
      before do
        sign_in user
      end

      it "renders the iframe view with authentication token scoped to same-origin" do
        host! "forem.com"
        get "/auth_pass/iframe"

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Security-Policy"]).to eq("frame-ancestors 'self'")
        expect(response.headers["X-Frame-Options"]).to eq("SAMEORIGIN")
        expect(response.headers["Cache-Control"]).to include("no-store")
        expect(response.body).to include("authenticated: true")
        expect(response.body).to include('window.parent.postMessage(data, "http://forem.com")')
        expect(response.body).not_to include("postMessage(data, '*')")
      end

      it "scopes postMessage and CSP frame-ancestors to an allowed subforem origin" do
        host! "forem.com"
        get "/auth_pass/iframe", params: { passed_domain: "https://#{allowed_origin}" }

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Security-Policy"]).to eq("frame-ancestors 'self' https://#{allowed_origin}")
        expect(response.headers["X-Frame-Options"]).to be_nil
        expect(response.body).to include("authenticated: true")
        expect(response.body).to include(%(window.parent.postMessage(data, "https://#{allowed_origin}")))
        expect(response.body).not_to include("postMessage(data, '*')")
      end

      it "does not emit a token or allow framing for an unauthorized passed_domain" do
        host! "forem.com"
        get "/auth_pass/iframe", params: { passed_domain: "https://evil.example" }

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Security-Policy"]).to eq("frame-ancestors 'self'")
        expect(response.headers["X-Frame-Options"]).to eq("SAMEORIGIN")
        expect(response.body).to eq("<html><body></body></html>")
        expect(response.body).not_to include("token")
      end

      it "does not emit a token or allow framing for an unauthorized Referer" do
        host! "forem.com"
        get "/auth_pass/iframe", headers: { "Referer" => "https://evil.example/landing" }

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Security-Policy"]).to eq("frame-ancestors 'self'")
        expect(response.headers["X-Frame-Options"]).to eq("SAMEORIGIN")
        expect(response.body).to eq("<html><body></body></html>")
        expect(response.body).not_to include("token")
      end

      it "does not emit mobileToken for standard browser user agents" do
        host! "forem.com"
        get "/auth_pass/iframe", headers: { "User-Agent" => "Mozilla/5.0" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("token:")
        expect(response.body).not_to include("mobileToken:")
      end

      it "emits a separate mobile_api mobileToken alongside the auth_pass token for ForemWebView/1" do
        host! "forem.com"
        get "/auth_pass/iframe", headers: { "User-Agent" => "ForemWebView/1" }

        expect(response).to have_http_status(:ok)
        auth_pass_token = response.body[/token:\s*'([^']+)'/, 1]
        mobile_token = response.body[/mobileToken:\s*'([^']+)'/, 1]

        expect(auth_pass_token).to be_present
        expect(mobile_token).to be_present
        expect(mobile_token).not_to eq(auth_pass_token)

        expect(Authentication::AuthToken.decode_auth_pass(auth_pass_token)["purpose"]).to eq("auth_pass")
        expect(Authentication::AuthToken.decode_auth_pass(mobile_token)).to be_nil

        decoded_mobile = JWT.decode(mobile_token, Rails.application.secret_key_base, true, algorithm: "HS256")[0]
        expect(decoded_mobile["purpose"]).to eq("mobile_api")
        expect(decoded_mobile["user_id"]).to eq(user.id)
      end

      it "does not emit a token when the user account is locked" do
        user.update_column(:locked_at, Time.current)
        host! "forem.com"
        get "/auth_pass/iframe"

        expect(response.body).not_to include("token:")
        expect(response.body).not_to include("authenticated: true")
      end
    end

    context "when user is not signed in" do
      it "renders empty html with status ok" do
        host! "forem.com"
        get "/auth_pass/iframe"

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("<html><body></body></html>")
      end
    end

    context "with passed_domain from a custom organization domain" do
      let!(:organization) { create(:organization, custom_domain: "blog.myorg.com") }

      context "when org_custom_domain feature flag is enabled" do
        before do
          FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))
        end

        it "sets CSP frame-ancestors header with the passed custom domain" do
          host! "forem.com"
          get "/auth_pass/iframe", params: { passed_domain: "https://blog.myorg.com" }

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Security-Policy"]).to eq("frame-ancestors 'self' https://blog.myorg.com")
        end
      end

      context "when org_custom_domain feature flag is disabled" do
        before do
          FeatureFlag.disable(:org_custom_domain, FeatureFlag::Actor.new(organization))
        end

        it "does not set CSP frame-ancestors for the custom domain" do
          host! "forem.com"
          get "/auth_pass/iframe", params: { passed_domain: "https://blog.myorg.com" }

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Security-Policy"]).not_to include("blog.myorg.com")
        end
      end
    end
  end
end
