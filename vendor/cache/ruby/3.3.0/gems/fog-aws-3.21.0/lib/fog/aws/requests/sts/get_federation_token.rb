module Fog
  module AWS
    class STS
      class Real
        require 'fog/aws/parsers/sts/get_session_token'

        # Get federation token
        #
        # ==== Parameters
        # * name<~String>: The name of the federated user.
        #                  Minimum length of 2. Maximum length of 32.
        # * policy<~String>: Optional policy that specifies the permissions
        #                    that are granted to the federated user
        #                    Minimum length of 1. Maximum length of 2048.
        # * duration<~Integer>: Optional duration, in seconds, that the session
        #                       should last.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'SessionToken'<~String> -
        #     * 'SecretAccessKey'<~String> -
        #     * 'Expiration'<~String> -
        #     * 'AccessKeyId'<~String> -
        #     * 'Arn'<~String> -
        #     * 'FederatedUserId'<~String> -
        #     * 'PackedPolicySize'<~String> -
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.aws.amazon.com/STS/latest/APIReference/API_GetFederationToken.html

        def get_federation_token(name, policy, duration=43200)
          request({
            'Action'          => 'GetFederationToken',
            'Name'            => name,
            'Policy'          => Fog::JSON.encode(policy),
            'DurationSeconds' => duration,
            :idempotent       => true,
            :parser           => Fog::Parsers::AWS::STS::GetSessionToken.new
          })
        end
      end
      class Mock
        def get_federation_token(name, policy, duration=43200)
          Excon::Response.new.tap do |response|
            response.status = 200
            response.body = {
            'SessionToken'     => Fog::Mock.random_base64(580),
            'SecretAccessKey'  => Fog::Mock.random_base64(40),
            'Expiration'       => (DateTime.now + duration).strftime('%FT%TZ'),
            'AccessKeyId'      => Fog::AWS::Mock.key_id(20),
            'Arn'              => "arn:aws:sts::#{Fog::AWS::Mock.owner_id}:federated-user/#{name}",
            'FederatedUserId'  => "#{Fog::AWS::Mock.owner_id}:#{name}",
            'PackedPolicySize' => Fog::Mock.random_numbers(2),
            'RequestId'        => Fog::AWS::Mock.request_id
            }
          end
        end
      end
    end
  end
end
