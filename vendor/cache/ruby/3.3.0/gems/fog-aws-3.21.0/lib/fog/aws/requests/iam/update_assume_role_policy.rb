module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Creates a managed policy
        #
        # ==== Parameters
        # * policy_document<~Hash>: policy document, see: http://docs.amazonwebservices.com/IAM/latest/UserGuide/PoliciesOverview.html
        # * role_name<~String>: name of role to update
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_UpdateAssumeRolePolicy.html
        #
        def update_assume_role_policy(policy_document, role_name)
          request({
            'Action'          => 'UpdateAssumeRolePolicy',
            'PolicyDocument'  => Fog::JSON.encode(policy_document),
            'RoleName'        => role_name,
            :parser           => Fog::Parsers::AWS::IAM::Basic.new
          }.reject {|_, value| value.nil?})
        end
        
        class Mock
          def update_assume_role_policy(policy_document, role_name)
            Excon::Response.new.tap do |response|
              response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
              response.status = 200
            end
          end
        end
      end
    end
  end
end
