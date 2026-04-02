module Api
  module V0
    class MobileAuthController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      def create
        provider = params[:provider]
        access_token = params[:access_token]
        code_verifier = params[:code_verifier]
        
        # Step 1: Verify the OAuth Token using Faraday
        unless %w[google_oauth2 github facebook mlh twitter2].include?(provider)
          return render json: { error: 'Unsupported auth provider' }, status: :bad_request
        end

        begin
          case provider
          when "google_oauth2"
            response = Faraday.get("https://oauth2.googleapis.com/tokeninfo") do |req|
              req.params['access_token'] = access_token
            end
            parsed_response = JSON.parse(response.body)
            
            if response.status != 200 || parsed_response["error"].present?
              return render json: { error: 'Invalid access token' }, status: :unauthorized
            end
            extracted_email = parsed_response["email"]
            extracted_uid = parsed_response["sub"]

          when "github"
            response = Faraday.get("https://api.github.com/user") do |req|
              req.headers['Authorization'] = "token #{access_token}"
              req.headers['Accept'] = "application/vnd.github.v3+json"
            end
            parsed_response = JSON.parse(response.body)
            
            if response.status != 200
              return render json: { error: 'Invalid access token' }, status: :unauthorized
            end
            extracted_email = parsed_response["email"]
            extracted_uid = parsed_response["id"].to_s
            
            # If email is private, Github might return nil. We should fetch it if necessary.
            if extracted_email.blank?
              emails_response = Faraday.get("https://api.github.com/user/emails") do |req|
                req.headers['Authorization'] = "token #{access_token}"
              end
              if emails_response.status == 200
                emails = JSON.parse(emails_response.body)
                primary_email = emails.find { |e| e["primary"] } || emails.first
                extracted_email = primary_email["email"] if primary_email
              end
            end

          when "facebook"
            response = Faraday.get("https://graph.facebook.com/me") do |req|
              req.params['access_token'] = access_token
              req.params['fields'] = "id,email"
            end
            parsed_response = JSON.parse(response.body)
            
            if response.status != 200 || parsed_response["error"].present?
              return render json: { error: 'Invalid access token' }, status: :unauthorized
            end
            extracted_email = parsed_response["email"]
            extracted_uid = parsed_response["id"]

          when "mlh"
            # MLH passes an authorization code rather than an implicit token
            exchange_response = Faraday.post("https://my.mlh.io/oauth/token") do |req|
              req.headers['Content-Type'] = 'application/json'
              req.body = {
                client_id: Settings::Authentication.mlh_key,
                client_secret: Settings::Authentication.mlh_secret,
                code: access_token,
                redirect_uri: "https://forem.com/users/auth/mlh/callback",
                grant_type: "authorization_code"
              }.to_json
            end
            
            if exchange_response.status != 200
              return render json: { error: 'Token exchange failed' }, status: :unauthorized
            end
            token = JSON.parse(exchange_response.body)["access_token"]
            
            response = Faraday.get("https://my.mlh.io/api/v3/user.json?access_token=#{token}")
            parsed_response = JSON.parse(response.body)
            
            if response.status != 200 || parsed_response["status"] == "Error"
              return render json: { error: 'Invalid user data' }, status: :unauthorized
            end
            extracted_email = parsed_response.dig("data", "email")
            extracted_uid = parsed_response.dig("data", "id").to_s

          when "twitter2"
            # Twitter passes an authorization code with PKCE rather than an implicit token
            exchange_response = Faraday.post("https://api.twitter.com/2/oauth2/token") do |req|
              req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
              req.headers['Authorization'] = "Basic #{Base64.strict_encode64("#{Settings::Authentication.twitter_key}:#{Settings::Authentication.twitter_secret}")}"
              req.body = URI.encode_www_form({
                code: access_token,
                grant_type: "authorization_code",
                client_id: Settings::Authentication.twitter_key,
                redirect_uri: "https://forem.com/users/auth/twitter/callback",
                code_verifier: code_verifier
              })
            end
            
            if exchange_response.status != 200
              return render json: { error: 'Token exchange failed' }, status: :unauthorized
            end
            token = JSON.parse(exchange_response.body)["access_token"]
            
            response = Faraday.get("https://api.twitter.com/2/users/me?user.fields=profile_image_url") do |req|
              req.headers['Authorization'] = "Bearer #{token}"
            end
            parsed_response = JSON.parse(response.body)
            
            if response.status != 200 || parsed_response["errors"].present?
              return render json: { error: 'Invalid user data' }, status: :unauthorized
            end
            
            # Reassign provider variable since Forem expects `twitter` for Identity records
            provider = "twitter" 
            extracted_email = parsed_response.dig("data", "email") # Might be nil if unshared
            extracted_uid = parsed_response.dig("data", "id").to_s
          end
        rescue StandardError => e
          Rails.logger.error "Mobile Auth Token Verification Failed: #{e.message}"
          return render json: { error: 'Token verification failed' }, status: :unauthorized
        end
        
        # Step 2: Form an OmniAuth Mock Hash
        auth_payload = OmniAuth::AuthHash.new({
          provider: provider,
          uid: extracted_uid,
          info: { email: extracted_email },
          credentials: { token: access_token, secret: '' },
          extra: { raw_info: parsed_response }
        })
        
        # Step 3: Match Identity to a User
        @user = ::Authentication::Authenticator.call(auth_payload)
        
        if @user&.persisted?
          # Step 4: Issue the Application JWT
          payload = {
            user_id: @user.id,
            exp: 30.days.from_now.to_i 
          }
          jwt_token = JWT.encode(payload, Rails.application.secret_key_base)
          render json: { jwt: jwt_token }, status: :ok
        else
          render json: { error: 'Authentication failed' }, status: :unauthorized
        end
      end
    end
  end
end
