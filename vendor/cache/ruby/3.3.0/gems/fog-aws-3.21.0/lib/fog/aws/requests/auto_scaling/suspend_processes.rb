module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Suspends Auto Scaling processes for an Auto Scaling group. To suspend
        # specific process types, specify them by name with the
        # ScalingProcesses parameter. To suspend all process types, omit the
        # ScalingProcesses.member.N parameter.
        #
        # ==== Parameters
        # * 'AutoScalingGroupName'<~String> - The name or Amazon Resource Name
        #   (ARN) of the Auto Scaling group.
        # * options<~Hash>:
        #   * 'ScalingProcesses'<~Array> - The processes that you want to
        #     suspend. To suspend all process types, omit this parameter.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_SuspendProcesses.html
        #
        def suspend_processes(auto_scaling_group_name, options = {})
          if scaling_processes = options.delete('ScalingProcesses')
            options.merge!(AWS.indexed_param('ScalingProcesses.member.%d', [*scaling_processes]))
          end
          request({
            'Action'               => 'SuspendProcesses',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def suspend_processes(auto_scaling_group_name, options = {})
          unless self.data[:auto_scaling_groups].key?(auto_scaling_group_name)
            raise Fog::AWS::AutoScaling::ValidationError.new("AutoScalingGroup name not found - no such group: #{auto_scaling_group_name}")
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
