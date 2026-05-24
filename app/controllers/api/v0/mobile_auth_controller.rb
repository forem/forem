module Api
  module V0
    class MobileAuthController < Api::V0::ApiController
      include Devise::Controllers::Helpers
      
      skip_before_action :verify_authenticity_token, only: :create
      
      def create
        provider = params[:provider]
        access_token = params[:access_token]
        code_verifier = params[:code_verifier]
        
        unless %w[google_oauth2 github facebook mlh twitter2].include?(provider)
          return render json: { error: 'Unsupported auth provider' }, status: :bad_request
        end

        begin
          extracted_email, extracted_uid, raw_info = verify_provider_token(provider, access_token, code_verifier)
          provider = 'twitter' if provider == 'twitter2'
        rescue StandardError => e
          Rails.logger.error "Mobile Auth Token Verification Failed: #{e.message}"
          return render json: { error: e.message }, status: :unauthorized
        end
        
        # Step 2: Form an OmniAuth Mock Hash
        auth_payload = OmniAuth::AuthHash.new({
          provider: provider,
          uid: extracted_uid,
          info: { email: extracted_email },
          credentials: { token: access_token, secret: '' },
          extra: { raw_info: raw_info }
        })
        
        # Step 3: Match Identity to a User
        begin
          @user = ::Authentication::Authenticator.call(auth_payload)
          
          if @user&.persisted?
            # Ensure the user passes the AuthPassController `user_not_signed_out?` validation
            @user.update_tracked_fields!(request)
            @user.save(validate: false)

            bypass_sign_in(@user)
            
            payload = { user_id: @user.id, exp: 30.days.from_now.to_i }
            jwt_token = JWT.encode(payload, Rails.application.secret_key_base)
            
            session_cookie_options = Rails.application.config.session_options.slice(:domain, :secure, :same_site)
            
            cookies[:jwt] = session_cookie_options.merge(
              value: jwt_token,
              expires: 30.days.from_now,
              httponly: true
            )
            
            render json: { jwt: jwt_token }, status: :ok
          else
            render json: { error: 'Authentication failed' }, status: :unauthorized
          end
        rescue ::Authentication::Errors::ProviderNotEnabled, ::Authentication::Errors::ProviderNotFound => e
          render json: { error: e.message }, status: :bad_request
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        rescue StandardError => e
          Rails.logger.error "Mobile Auth Exchange Authenticator Error: #{e.message}"
          render json: { error: 'Internal server processing error' }, status: :internal_server_error
        end
      end

      private

      def verify_provider_token(provider, access_token, code_verifier)
        case provider
        when "google_oauth2"
          verify_google_oauth2(access_token)
        when "github"
          verify_github(access_token)
        when "facebook"
          verify_facebook(access_token)
        when "mlh"
          verify_mlh(access_token)
        when "twitter2"
          verify_twitter2(access_token, code_verifier)
        end
      end

      def verify_google_oauth2(access_token)
        response = Faraday.get("https://oauth2.googleapis.com/tokeninfo") do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
          req.params['access_token'] = access_token
        end
        parsed_response = JSON.parse(response.body)
        
        if response.status != 200 || parsed_response["error"].present?
          raise StandardError, 'Invalid access token'
        end
        
        valid_clients = [
          Settings::Authentication.google_oauth2_key,
          Settings::Authentication.google_ios_key,
          Settings::Authentication.google_android_key
        ].reject(&:blank?)
        
        if !valid_clients.include?(parsed_response["aud"])
          raise StandardError, 'Token audience mismatch'
        end
        
        [parsed_response["email"], parsed_response["sub"], parsed_response]
      end

      def verify_github(access_token)
        # Verify audience using GitHub's token introspection endpoint
        debug_response = Faraday.post("https://api.github.com/applications/#{Settings::Authentication.github_key}/token") do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
          req.headers['Accept'] = "application/vnd.github.v3+json"
          req.headers['Content-Type'] = "application/json"
          # Introspection requires Basic Auth with Forem's Client ID & Secret
          req.headers['Authorization'] = "Basic #{Base64.strict_encode64("#{Settings::Authentication.github_key}:#{Settings::Authentication.github_secret}")}"
          req.body = { access_token: access_token }.to_json
        end
        
        if debug_response.status != 200
          raise StandardError, 'Token invalid or audience mismatch'
        end

        response = Faraday.get("https://api.github.com/user") do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
          req.headers['Authorization'] = "token #{access_token}"
          req.headers['Accept'] = "application/vnd.github.v3+json"
        end
        parsed_response = JSON.parse(response.body)
        
        if response.status != 200
          raise StandardError, 'Invalid access token'
        end
        
        extracted_email = parsed_response["email"]
        extracted_uid = parsed_response["id"].to_s
        
        if extracted_email.blank?
          emails_response = Faraday.get("https://api.github.com/user/emails") do |req|
            req.options.timeout = 10
            req.options.open_timeout = 5
            req.headers['Authorization'] = "token #{access_token}"
          end
          if emails_response.status == 200
            emails = JSON.parse(emails_response.body)
            primary_email = emails.find { |e| e["primary"] } || emails.first
            extracted_email = primary_email["email"] if primary_email
          end
        end
        
        [extracted_email, extracted_uid, parsed_response]
      end

      def verify_facebook(access_token)
        # Verify audience using debug_token
        debug_response = Faraday.get("https://graph.facebook.com/debug_token") do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
          req.params['input_token'] = access_token
          req.params['access_token'] = "#{Settings::Authentication.facebook_key}|#{Settings::Authentication.facebook_secret}"
        end
        debug_parsed = JSON.parse(debug_response.body)
        
        if debug_response.status != 200 || debug_parsed.dig("data", "error").present? || debug_parsed.dig("data", "is_valid") != true
          raise StandardError, 'Invalid access token'
        end
        
        if debug_parsed.dig("data", "app_id") != Settings::Authentication.facebook_key
          raise StandardError, 'Token audience mismatch'
        end

        response = Faraday.get("https://graph.facebook.com/me") do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
          req.params['access_token'] = access_token
          req.params['fields'] = "id,email"
        end
        parsed_response = JSON.parse(response.body)
        
        if response.status != 200 || parsed_response["error"].present?
          raise StandardError, 'Invalid access token'
        end
        [parsed_response["email"], parsed_response["id"], parsed_response]
      end

      def verify_mlh(access_token)
        exchange_response = Faraday.post("https://my.mlh.io/oauth/token") do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            client_id: Settings::Authentication.mlh_key,
            client_secret: Settings::Authentication.mlh_secret,
            code: access_token,
            redirect_uri: "#{URL.url}/users/auth/mlh/callback",
            grant_type: "authorization_code"
          }.to_json
        end
        
        if exchange_response.status != 200
          raise StandardError, 'Token exchange failed'
        end
        access_token_exchanged = JSON.parse(exchange_response.body)["access_token"]
        
        response = Faraday.get("https://my.mlh.io/api/v3/user.json?access_token=#{access_token_exchanged}") do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
        end
        parsed_response = JSON.parse(response.body)
        
        if response.status != 200 || parsed_response["status"] == "Error"
          raise StandardError, 'Invalid user data'
        end
        [parsed_response.dig("data", "email"), parsed_response.dig("data", "id").to_s, parsed_response]
      end

      def verify_twitter2(access_token, code_verifier)
        exchange_response = Faraday.post("https://api.twitter.com/2/oauth2/token") do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          req.headers['Authorization'] = "Basic #{Base64.strict_encode64("#{Settings::Authentication.twitter_key}:#{Settings::Authentication.twitter_secret}")}"
          req.body = URI.encode_www_form({
            code: access_token,
            grant_type: "authorization_code",
            client_id: Settings::Authentication.twitter_key,
            redirect_uri: "#{URL.url}/users/auth/twitter/callback",
            code_verifier: code_verifier
          })
        end
        
        if exchange_response.status != 200
          raise StandardError, 'Token exchange failed'
        end
        access_token_exchanged = JSON.parse(exchange_response.body)["access_token"]
        
        response = Faraday.get("https://api.twitter.com/2/users/me?user.fields=profile_image_url") do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
          req.headers['Authorization'] = "Bearer #{access_token_exchanged}"
        end
        parsed_response = JSON.parse(response.body)
        
        if response.status != 200 || parsed_response["errors"].present?
          raise StandardError, 'Invalid user data'
        end
        
        [parsed_response.dig("data", "email"), parsed_response.dig("data", "id").to_s, parsed_response]
      end
    end
  end
end
