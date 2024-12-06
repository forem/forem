module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Deletes a policy created by put_scaling_policy
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        #   group.
        # * policy_name<~String> - The name or PolicyARN of the policy you want
        #   to delete.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeletePolicy.html
        #
        def delete_policy(auto_scaling_group_name, policy_name)
          request({
            'Action'               => 'DeletePolicy',
            'AutoScalingGroupName' => auto_scaling_group_name,
            'PolicyName'           => policy_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          })
        end
      end

      class Mock
        def delete_policy(auto_scaling_group_name, policy_name)
          unless self.data[:scaling_policies].delete(policy_name)
            raise Fog::AWS::AutoScaling::NotFound, "The scaling policy '#{policy_name}' does not exist."
          end

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
