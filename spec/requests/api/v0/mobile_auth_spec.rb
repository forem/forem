require 'rails_helper'

RSpec.describe 'Api::V0::MobileAuth', type: :request do
  let(:valid_access_token) { 'ya29.valid_token_string' }
  let(:invalid_access_token) { 'ya29.invalid_token_string' }
  let(:user) { create(:user) }
  
  before do
    # Stub Faraday Google Token request for valid token
    stub_request(:get, "https://oauth2.googleapis.com/tokeninfo?access_token=#{valid_access_token}").
      to_return(status: 200, body: {
        "email" => user.email,
        "sub" => "1234567890"
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    # Stub Faraday request for invalid token
    stub_request(:get, "https://oauth2.googleapis.com/tokeninfo?access_token=#{invalid_access_token}").
      to_return(status: 400, body: {
        "error" => "invalid_token",
        "error_description" => "Invalid Value"
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    # Stub Faraday Github Token request for valid token
    stub_request(:get, "https://api.github.com/user").
      with(headers: { 'Authorization' => "token #{valid_access_token}" }).
      to_return(status: 200, body: {
        "email" => user.email,
        "id" => 1234567890
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    # Stub Faraday Facebook Token request for valid token
    stub_request(:get, "https://graph.facebook.com/me?access_token=#{valid_access_token}&fields=id,email").
      to_return(status: 200, body: {
        "email" => user.email,
        "id" => "1234567890"
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    # Stub MLH token exchange and user fetch
    stub_request(:post, "https://my.mlh.io/oauth/token").
      to_return(status: 200, body: { "access_token" => "mlh_mock_token" }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, "https://my.mlh.io/api/v3/user.json?access_token=mlh_mock_token").
      to_return(status: 200, body: {
        "status" => "OK",
        "data" => { "email" => user.email, "id" => 123 }
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    # Stub Twitter token exchange and user fetch
    stub_request(:post, "https://api.twitter.com/2/oauth2/token").
      to_return(status: 200, body: { "access_token" => "twitter_mock_token" }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, "https://api.twitter.com/2/users/me?user.fields=profile_image_url").
      with(headers: { 'Authorization' => 'Bearer twitter_mock_token' }).
      to_return(status: 200, body: {
        "data" => { "id" => "456", "email" => user.email }
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    allow(Authentication::Providers).to receive(:enabled?).and_return(true)
    allow(Settings::Authentication).to receive(:mlh_key).and_return("mock_mlh_key")
    allow(Settings::Authentication).to receive(:mlh_secret).and_return("mock_mlh_secret")
    allow(Settings::Authentication).to receive(:twitter_key).and_return("mock_twitter_key")
    allow(Settings::Authentication).to receive(:twitter_secret).and_return("mock_twitter_secret")
  end

  describe 'POST /api/v0/auth/mobile_exchange' do
    context 'with a valid google_oauth2 provider' do
      it 'authenticates the user and returns a Forem JWT' do
        post '/api/auth/mobile_exchange', params: {
          provider: 'google_oauth2',
          access_token: valid_access_token
        }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['jwt']).to be_present
        
        # Verify JWT payload matches user
        decoded_token = JWT.decode(json_response['jwt'], Rails.application.secret_key_base).first
        
        authed_user = User.find(decoded_token['user_id'])
        expect(authed_user.email).to eq(user.email)
        expect(decoded_token['exp']).to be > 29.days.from_now.to_i
      end
    end

    context 'with a valid github provider' do
      it 'authenticates the user and returns a Forem JWT' do
        post '/api/auth/mobile_exchange', params: {
          provider: 'github',
          access_token: valid_access_token
        }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['jwt']).to be_present
        
        decoded_token = JWT.decode(json_response['jwt'], Rails.application.secret_key_base).first
        authed_user = User.find(decoded_token['user_id'])
        expect(authed_user.email).to eq(user.email)
      end
    end

    context 'with a valid facebook provider' do
      it 'authenticates the user and returns a Forem JWT' do
        post '/api/auth/mobile_exchange', params: {
          provider: 'facebook',
          access_token: valid_access_token
        }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['jwt']).to be_present
        
        decoded_token = JWT.decode(json_response['jwt'], Rails.application.secret_key_base).first
        authed_user = User.find(decoded_token['user_id'])
        expect(authed_user.email).to eq(user.email)
      end
    end

    context 'with a valid mlh provider' do
      it 'authenticates the user and returns a Forem JWT after exchanging the code' do
        post '/api/auth/mobile_exchange', params: {
          provider: 'mlh',
          access_token: 'valid_code'
        }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['jwt']).to be_present
        
        decoded_token = JWT.decode(json_response['jwt'], Rails.application.secret_key_base).first
        authed_user = User.find(decoded_token['user_id'])
        expect(authed_user.email).to eq(user.email)
      end
    end

    context 'with a valid twitter provider' do
      it 'authenticates the user and returns a Forem JWT after exchanging the code' do
        post '/api/auth/mobile_exchange', params: {
          provider: 'twitter2',
          access_token: 'valid_code',
          code_verifier: 'mock_verifier'
        }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['jwt']).to be_present
        
        decoded_token = JWT.decode(json_response['jwt'], Rails.application.secret_key_base).first
        authed_user = User.find(decoded_token['user_id'])
        expect(authed_user.email).to eq(user.email)
      end
    end

    context 'with an invalid access token' do
      it 'returns unauthorized' do
        post '/api/auth/mobile_exchange', params: {
          provider: 'google_oauth2',
          access_token: invalid_access_token
        }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid access token')
      end
    end

    context 'with an unsupported provider' do
      it 'returns bad request' do
        post '/api/auth/mobile_exchange', params: {
          provider: 'apple',
          access_token: 'some_token'
        }
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unsupported auth provider')
      end
    end
  end
end
