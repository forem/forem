module Fog
  module AWS
    class Federation
      class Real
        def get_signin_token(session)

          request('getSigninToken', CGI.escape(Fog::JSON.encode(session)))
        end
      end

      class Mock
        def get_signin_token(session)
          {
            'SigninToken' => Fog::Mock.random_base64(752)
          }
        end
      end
    end
  end
end
