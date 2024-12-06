module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_launch_configurations'

        # Returns a full description of the launch configurations given the
        # specified names.
        #
        # If no names are specified, then the full details of all launch
        # configurations are returned.
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'LaunchConfigurationNames'<~Array> - A list of launch
        #     configuration names.
        #   * 'MaxRecords'<~Integer> - The maximum number of launch
        #     configurations.
        #   * 'NextToken'<~String> - The token returned by a previous call to
        #     indicate that there is more data available.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeLaunchConfigurationsResponse'<~Hash>:
        #       * 'LaunchConfigurations'<~Array>:
        #         * launchconfiguration'<~Hash>:
        #           * 'BlockDeviceMappings'<~Array>:
        #             * blockdevicemapping<~Hash>:
        #               * 'DeviceName'<~String> - The name of the device within
        #                 EC2.
        #               * 'Ebs'<~Hash>:
        #                 * 'SnapshotId'<~String> - The snapshot ID
        #                 * 'VolumeSize'<~Integer> - The volume size, in
        #                   GigaBytes.
        #               * 'VirtualName'<~String> - The virtual name associated
        #                 with the device.
        #           * 'CreatedTime'<~Time> - Provides the creation date and
        #             time for this launch configuration.
        #           * 'ImageId'<~String> - Provides the unique ID of the Amazon
        #             Machine Image (AMI) that was assigned during
        #             registration.
        #           * 'InstanceMonitoring'<~Hash>:
        #             * 'Enabled'<~Boolean> - If true, instance monitoring is
        #               enabled.
        #           * 'InstanceType'<~String> - Specifies the instance type of
        #             the EC2 instance.
        #           * 'KernelId'<~String> - Provides the ID of the kernel
        #             associated with the EC2 AMI.
        #           * 'KeyName'<~String> - Provides the name of the EC2 key
        #             pair.
        #           * 'LaunchConfigurationARN'<~String> - The launch
        #             configuration's Amazon Resource Name (ARN).
        #           * 'LaunchConfigurationName'<~String> - Specifies the name
        #             of the launch configuration.
        #           * 'RamdiskId'<~String> - Provides ID of the RAM disk
        #             associated with the EC2 AMI.
        #           * 'PlacementTenancy'<~String> - The tenancy of the instance.
        #           * 'SecurityGroups'<~Array> - A description of the security
        #             groups to associate with the EC2 instances.
        #           * 'UserData'<~String> - The user data available to the
        #             launched EC2 instances.
        #       * 'NextToken'<~String> - Acts as a paging mechanism for large
        #         result sets. Set to a non-empty string if there are
        #         additional results waiting to be returned. Pass this in to
        #         subsequent calls to return additional results.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeLaunchConfigurations.html
        #
        def describe_launch_configurations(options = {})
          if launch_configuration_names = options.delete('LaunchConfigurationNames')
            options.merge!(AWS.indexed_param('LaunchConfigurationNames.member.%d', [*launch_configuration_names]))
          end
          request({
            'Action' => 'DescribeLaunchConfigurations',
            :parser  => Fog::Parsers::AWS::AutoScaling::DescribeLaunchConfigurations.new
          }.merge!(options))
        end
      end

      class Mock
        def describe_launch_configurations(options = {})
          launch_configuration_names = options.delete('LaunchConfigurationNames')
          # even a nil object will turn into an empty array
          lc = [*launch_configuration_names]

          launch_configurations =
             if lc.any?
               lc.map do |lc_name|
                 l_conf = self.data[:launch_configurations].find { |name, data| name == lc_name }
                 #raise Fog::AWS::AutoScaling::NotFound unless l_conf
                 l_conf[1].dup if l_conf
               end.compact
             else
               self.data[:launch_configurations].map { |lc, values| values.dup }
             end

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribeLaunchConfigurationsResult' => { 'LaunchConfigurations' => launch_configurations },
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
