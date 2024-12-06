module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Remove a policy from a group
        #
        # ==== Parameters
        # * group_name<~String>: name of the group
        # * policy_name<~String>: name of policy document
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteGroupPolicy.html
        #
        def delete_group_policy(group_name, policy_name)
          request(
            'Action'          => 'DeleteGroupPolicy',
            'GroupName'       => group_name,
            'PolicyName'      => policy_name,
            :parser           => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def delete_group_policy(group_name, policy_name)
          if !data[:groups].key? group_name
            raise Fog::AWS::IAM::NotFound.new("The group with name #{group_name} cannot be found.")
          elsif !data[:groups][group_name][:policies].key? policy_name
            raise Fog::AWS::IAM::NotFound.new("The group policy with name #{policy_name} cannot be found.")
          else
            data[:groups][group_name][:policies].delete(policy_name)

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
