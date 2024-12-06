module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'
        # Add or update the account password policy
        #
        # ==== Parameters
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_UpdateAccountPasswordPolicy.html
        #
        def delete_account_password_policy
          request({
            'Action'          => 'DeleteAccountPasswordPolicy',
            :parser           => Fog::Parsers::AWS::IAM::Basic.new
          })
        end
      end

      class Mock
        def delete_account_password_policy
          Excon::Response.new.tap do |response|
            response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
            response.status = 200
          end
        end
      end
    end
  end
end
