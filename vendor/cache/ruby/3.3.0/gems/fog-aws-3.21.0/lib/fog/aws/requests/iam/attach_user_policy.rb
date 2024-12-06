module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Attaches a managed policy to a user
        #
        # ==== Parameters
        # * user_name<~String>: name of the user
        # * policy_arn<~String>: arn of the managed policy
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_AttachUserPolicy.html
        #
        def attach_user_policy(user_name, policy_arn)
          request(
            'Action'    => 'AttachUserPolicy',
            'UserName'  => user_name,
            'PolicyArn' => policy_arn,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def attach_user_policy(user_name, policy_arn)
          if policy_arn.nil?
            raise Fog::AWS::IAM::ValidationError, "1 validation error detected: Value null at 'policyArn' failed to satisfy constraint: Member must not be null"
          end

          managed_policy = self.data[:managed_policies][policy_arn]

          unless managed_policy
            raise Fog::AWS::IAM::NotFound, "Policy #{policy_arn} does not exist."
          end

          unless self.data[:users].key?(user_name)
            raise Fog::AWS::IAM::NotFound.new("The user with name #{user_name} cannot be found.")
          end

          user = self.data[:users][user_name]
          user[:attached_policies] << policy_arn
          managed_policy['AttachmentCount'] += 1

          Excon::Response.new.tap { |response|
            response.status = 200
            response.body = { "RequestId" => Fog::AWS::Mock.request_id  }
          }
        end
      end
    end
  end
end
