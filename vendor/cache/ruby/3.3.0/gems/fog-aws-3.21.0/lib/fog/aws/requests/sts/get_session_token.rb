module Fog
  module AWS
    class STS
      class Real
        require 'fog/aws/parsers/sts/get_session_token'

        def get_session_token(duration=43200)
          request({
            'Action'          => 'GetSessionToken',
            'DurationSeconds' => duration,
            :idempotent       => true,
            :parser           => Fog::Parsers::AWS::STS::GetSessionToken.new
          })
        end
      end
    end
  end
end
