module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Attaches a managed policy to a group
        #
        # ==== Parameters
        # * group_name<~String>: name of the group
        # * policy_arn<~String>: arn of the managed policy
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_AttachGroupPolicy.html
        #
        def attach_group_policy(group_name, policy_arn)
          request(
            'Action'    => 'AttachGroupPolicy',
            'GroupName' => group_name,
            'PolicyArn' => policy_arn,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def attach_group_policy(group_name, policy_arn)
          if policy_arn.nil?
            raise Fog::AWS::IAM::ValidationError, "1 validation error detected: Value null at 'policyArn' failed to satisfy constraint: Member must not be null"
          end

          managed_policy = self.data[:managed_policies][policy_arn]

          unless managed_policy
            raise Fog::AWS::IAM::NotFound, "Policy #{policy_arn} does not exist."
          end

          unless self.data[:groups].key?(group_name)
            raise Fog::AWS::IAM::NotFound.new("The group with name #{group_name} cannot be found.")
          end

          group = self.data[:groups][group_name]
          group[:attached_policies] << policy_arn
          managed_policy["AttachmentCount"] += 1

          Excon::Response.new.tap { |response|
            response.status = 200
            response.body = { "RequestId" => Fog::AWS::Mock.request_id  }
          }
        end
      end
    end
  end
end
