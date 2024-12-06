module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Add or update a policy for a role
        #
        # ==== Parameters
        # * role_name<~String>: name of the role
        # * policy_name<~String>: name of policy document
        # * policy_document<~Hash>: policy document, see: http://docs.amazonwebservices.com/IAM/latest/UserGuide/PoliciesOverview.html
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_PutRolePolicy.html
        #
        def put_role_policy(role_name, policy_name, policy_document)
          request(
            'Action'          => 'PutRolePolicy',
            'RoleName'       => role_name,
            'PolicyName'      => policy_name,
            'PolicyDocument'  => Fog::JSON.encode(policy_document),
            :parser           => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end
    end
  end
end
