# spec/requests/auth_pass_spec.rb
require 'rails_helper'

RSpec.describe "AuthPassController", type: :request do
  let(:user) { create(:user) }

  # Helper method to generate a valid token
  def generate_auth_token(user)
    payload = {
      user_id: user.id,
      exp: 5.minutes.from_now.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base)
  end

  # Helper method to generate an expired token
  def generate_expired_auth_token(user)
    payload = {
      user_id: user.id,
      exp: 5.minutes.ago.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base)
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
  end
end
