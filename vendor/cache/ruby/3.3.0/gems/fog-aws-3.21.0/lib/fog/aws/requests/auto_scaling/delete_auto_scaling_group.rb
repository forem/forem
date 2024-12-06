module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Deletes the specified auto scaling group if the group has no
        # instances and no scaling activities in progress.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        #   group.
        # * options<~Hash>:
        #   * 'ForceDelete'<~Boolean> - Starting with API version 2011-01-01,
        #     specifies that the Auto Scaling group will be deleted along with
        #     all instances associated with the group, without waiting for all
        #     instances to be terminated.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteAutoScalingGroup.html
        #
        def delete_auto_scaling_group(auto_scaling_group_name, options = {})
          request({
            'Action'               => 'DeleteAutoScalingGroup',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def delete_auto_scaling_group(auto_scaling_group_name, options = {})
          unless self.data[:auto_scaling_groups].delete(auto_scaling_group_name)
            raise Fog::AWS::AutoScaling::ValidationError, "The auto scaling group '#{auto_scaling_group_name}' does not exist."
          end

          self.data[:notification_configurations].delete(auto_scaling_group_name)

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
