module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Detaches a managed policy from a role
        #
        # ==== Parameters
        # * role_name<~String>: name of the role
        # * policy_arn<~String>: arn of the managed policy
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_DetachRolePolicy.html
        #
        def detach_role_policy(role_name, policy_arn)
          request(
            'Action'          => 'DetachRolePolicy',
            'RoleName'       => role_name,
            'PolicyArn'      => policy_arn,
            :parser           => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def detach_role_policy(role_name, policy_arn)
          response = Excon::Response.new

          if policy_arn.nil?
            raise Fog::AWS::IAM::ValidationError, "1 validation error detected: Value null at 'policyArn' failed to satisfy constraint: Member must not be null"
          end

          managed_policy = self.data[:managed_policies][policy_arn]

          unless managed_policy
            raise Fog::AWS::IAM::NotFound, "Policy #{policy_arn} does not exist."
          end

          unless self.data[:roles].key?(role_name)
            raise Fog::AWS::IAM::NotFound.new("The role with name #{role_name} cannot be found.")
          end

          role = self.data[:roles][role_name]
          role[:attached_policies].delete(policy_arn)
          managed_policy["AttachmentCount"] -= 1

          response.body = {"RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
