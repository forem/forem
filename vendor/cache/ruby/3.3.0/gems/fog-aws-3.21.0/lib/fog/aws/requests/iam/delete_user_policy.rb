module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Remove a policy from a user
        #
        # ==== Parameters
        # * user_name<~String>: name of the user
        # * policy_name<~String>: name of policy document
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteUserPolicy.html
        #
        def delete_user_policy(user_name, policy_name)
          request(
            'Action'          => 'DeleteUserPolicy',
            'PolicyName'      => policy_name,
            'UserName'        => user_name,
            :parser           => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def delete_user_policy(user_name, policy_name)
          if data[:users].key?(user_name) && data[:users][user_name][:policies].key?(policy_name)
            data[:users][user_name][:policies].delete policy_name
            Excon::Response.new.tap do |response|
              response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
              response.status = 200
            end
          else
            raise Fog::AWS::IAM::NotFound.new("The user policy with name #{policy_name} cannot be found.")
          end
        end
      end
    end
  end
end
