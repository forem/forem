module Rpush
  module Daemon
    module Apnsp8
      TOKEN_TTL = 30 * 60
      class Token
        def initialize(app)
          @app = app
        end

        def token
          if @cached_token && !expired_token?
            @cached_token
          else
            new_token
          end
        end

        private

        def new_token
          @cached_token_at = Time.now
          ec_key = OpenSSL::PKey::EC.new(@app.apn_key)
          @cached_token = JWT.encode(
            {
              iss: @app.team_id,
              iat: Time.now.to_i
            },
            ec_key,
            'ES256',
            {
              alg: 'ES256',
              kid: @app.apn_key_id
            }
          )
        end

        def expired_token?
          Time.now - @cached_token_at >= TOKEN_TTL
        end
      end
    end
  end
end
