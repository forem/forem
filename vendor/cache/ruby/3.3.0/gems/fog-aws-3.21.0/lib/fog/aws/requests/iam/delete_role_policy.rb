module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Remove a policy from a role
        #
        # ==== Parameters
        # * role_name<~String>: name of the role
        # * policy_name<~String>: name of policy document
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteRolePolicy.html
        #
        def delete_role_policy(role_name, policy_name)
          request(
            'Action'          => 'DeleteRolePolicy',
            'PolicyName'      => policy_name,
            'RoleName'        => role_name,
            :parser           => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end
    end
  end
end
