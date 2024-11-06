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
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  # Helper method to generate an expired token
  def generate_expired_auth_token(user)
    payload = {
      user_id: user.id,
      exp: 5.minutes.ago.to_i
    }
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  # Helper method to parse JSON responses
  def json_response
    JSON.parse(response.body)
  end

  describe "GET /auth_pass/iframe" do
    context "when user is signed in" do
      before do
        sign_in user
        get '/auth_pass/iframe'
      end

      it "includes authenticated: true and the token in the response body" do
        expect(response.body).to include('authenticated: true')
        expect(response.body).to match(/token: '(.+)'/)
      end

      it "sets X-Frame-Options header to ALLOWALL" do
        expect(response.headers['X-Frame-Options']).to eq('ALLOWALL')
      end
    end

    context "when user is not signed in" do
      before { get '/auth_pass/iframe' }

      it "includes authenticated: false and an empty token in the response body" do
        expect(response.body).to include('authenticated: false')
        expect(response.body).to include('token: \'\'')
      end

      it "sets X-Frame-Options header to ALLOWALL" do
        expect(response.headers['X-Frame-Options']).to eq('ALLOWALL')
      end
    end
  end

  describe "POST /auth_pass/token_login" do
    context "with a valid token" do
      context "when the user exists" do
        it "signs in the user and returns success: true" do
          token = generate_auth_token(user)

          post '/auth_pass/token_login', params: { token: token }

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include("application/json")
          expect(json_response['success']).to be true
        end
      end

      context "when the user does not exist" do
        it "returns success: false with 'User not found' error" do
          token = generate_auth_token(user)
          user.destroy

          post '/auth_pass/token_login', params: { token: token }

          expect(response).to have_http_status(:unauthorized)
          expect(json_response['success']).to be false
          expect(json_response['error']).to eq('User not found')
        end
      end
    end

    context "with an invalid token" do
      it "returns success: false with 'Invalid token' error" do
        post '/auth_pass/token_login', params: { token: 'invalid_token' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Invalid token')
      end
    end

    context "with an expired token" do
      it "returns success: false with 'Invalid token' error" do
        token = generate_expired_auth_token(user)

        post '/auth_pass/token_login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Invalid token')
      end
    end
  end
end
