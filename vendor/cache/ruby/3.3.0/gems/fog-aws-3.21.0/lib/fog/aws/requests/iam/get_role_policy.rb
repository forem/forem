module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/get_role_policy'

        # Get Role Policy
        #
        # ==== Parameters
        # * 'PolicyName'<~String>: Name of the policy to get
        # * 'RoleName'<~String>: Name of the Role who the policy is associated with.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #       * PolicyDocument<~String> The policy document.
        #       * PolicyName<~String> The name of the policy.
        #       * RoleName<~String> The Role the policy is associated with.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetRolePolicy.html
        #
        def get_role_policy(role_name, policy_name)
          request({
            'Action'      => 'GetRolePolicy',
            'PolicyName'  => policy_name,
            'RoleName'    => role_name,
            :parser       => Fog::Parsers::AWS::IAM::GetRolePolicy.new
          })
        end
      end
    end
  end
end
