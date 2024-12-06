module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_instances'

        # Describe all or specified instances
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #   * Also allows for passing of optional parameters to fetch instances in batches:
        #     * 'maxResults' - The number of instances to return for the request
        #     * 'nextToken' - The token to fetch the next set of items. This is returned by a previous request.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'nextToken' - The token to use when requesting the next set of items when fetching items in batches.
        #     * 'reservationSet'<~Array>:
        #       * 'groupSet'<~Array> - Group names for reservation
        #       * 'ownerId'<~String> - AWS Access Key ID of reservation owner
        #       * 'reservationId'<~String> - Id of the reservation
        #       * 'instancesSet'<~Array>:
        #         * instance<~Hash>:
        #           * 'architecture'<~String> - architecture of image in [i386, x86_64]
        #           * 'amiLaunchIndex'<~Integer> - reference to instance in launch group
        #           * 'blockDeviceMapping'<~Array>
        #             * 'attachTime'<~Time> - time of volume attachment
        #             * 'deleteOnTermination'<~Boolean> - whether or not to delete volume on termination
        #             * 'deviceName'<~String> - specifies how volume is exposed to instance
        #             * 'status'<~String> - status of attached volume
        #             * 'volumeId'<~String> - Id of attached volume
        #           * 'dnsName'<~String> - public dns name, blank until instance is running
        #           * 'ebsOptimized'<~Boolean> - Whether the instance is optimized for EBS I/O
        #           * 'imageId'<~String> - image id of ami used to launch instance
        #           * 'instanceId'<~String> - id of the instance
        #           * 'instanceState'<~Hash>:
        #             * 'code'<~Integer> - current status code
        #             * 'name'<~String> - current status name
        #           * 'instanceType'<~String> - type of instance
        #           * 'ipAddress'<~String> - public ip address assigned to instance
        #           * 'kernelId'<~String> - id of kernel used to launch instance
        #           * 'keyName'<~String> - name of key used launch instances or blank
        #           * 'launchTime'<~Time> - time instance was launched
        #           * 'monitoring'<~Hash>:
        #             * 'state'<~Boolean - state of monitoring
        #           * 'placement'<~Hash>:
        #             * 'availabilityZone'<~String> - Availability zone of the instance
        #           * 'platform'<~String> - Platform of the instance (e.g., Windows).
        #           * 'productCodes'<~Array> - Product codes for the instance
        #           * 'privateDnsName'<~String> - private dns name, blank until instance is running
        #           * 'privateIpAddress'<~String> - private ip address assigned to instance
        #           * 'rootDeviceName'<~String> - specifies how the root device is exposed to the instance
        #           * 'rootDeviceType'<~String> - root device type used by AMI in [ebs, instance-store]
        #           * 'ramdiskId'<~String> - Id of ramdisk used to launch instance
        #           * 'reason'<~String> - reason for most recent state transition, or blank
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeInstances.html]
        def describe_instances(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_instances with #{filters.class} param is deprecated, use describe_instances('instance-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'instance-id' => [*filters]}
          end
          params = {}

          next_token  = filters.delete('nextToken') || filters.delete('NextToken')
          max_results = filters.delete('maxResults') || filters.delete('MaxResults')

          if filters['instance-id']
            instance_ids = filters.delete('instance-id')
            instance_ids = [instance_ids] unless instance_ids.is_a?(Array)
            instance_ids.each_with_index do |id, index|
              params.merge!("InstanceId.#{index}" => id)
            end
          end

          params['NextToken']  = next_token if next_token
          params['MaxResults'] = max_results if max_results
          params.merge!(Fog::AWS.indexed_filters(filters))

          request({
            'Action'    => 'DescribeInstances',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeInstances.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_instances(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_instances with #{filters.class} param is deprecated, use describe_instances('instance-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'instance-id' => [*filters]}
          end

          response = Excon::Response.new

          instance_set = self.data[:instances].values
          instance_set = apply_tag_filters(instance_set, filters, 'instanceId')

          aliases = {
            'architecture'             => 'architecture',
            'availability-zone'        => 'availabilityZone',
            'client-token'             => 'clientToken',
            'dns-name'                 => 'dnsName',
            'group-id'                 => 'groupId',
            'image-id'                 => 'imageId',
            'instance-id'              => 'instanceId',
            'instance-lifecycle'       => 'instanceLifecycle',
            'instance-type'            => 'instanceType',
            'ip-address'               => 'ipAddress',
            'kernel-id'                => 'kernelId',
            'key-name'                 => 'key-name',
            'launch-index'             => 'launchIndex',
            'launch-time'              => 'launchTime',
            'monitoring-state'         => 'monitoringState',
            'owner-id'                 => 'ownerId',
            'placement-group-name'     => 'placementGroupName',
            'platform'                 => 'platform',
            'private-dns-name'         => 'privateDnsName',
            'private-ip-address'       => 'privateIpAddress',
            'product-code'             => 'productCode',
            'ramdisk-id'               => 'ramdiskId',
            'reason'                   => 'reason',
            'requester-id'             => 'requesterId',
            'reservation-id'           => 'reservationId',
            'root-device-name'         => 'rootDeviceName',
            'root-device-type'         => 'rootDeviceType',
            'spot-instance-request-id' => 'spotInstanceRequestId',
            'subnet-id'                => 'subnetId',
            'virtualization-type'      => 'virtualizationType',
            'vpc-id'                   => 'vpcId'
          }
          block_device_mapping_aliases = {
            'attach-time'           => 'attachTime',
            'delete-on-termination' => 'deleteOnTermination',
            'device-name'           => 'deviceName',
            'status'                => 'status',
            'volume-id'             => 'volumeId',
          }
          instance_state_aliases = {
            'code' => 'code',
            'name' => 'name'
          }
          state_reason_aliases = {
            'code'    => 'code',
            'message' => 'message'
          }
          for filter_key, filter_value in filters
            if block_device_mapping_key = filter_key.split('block-device-mapping.')[1]
              aliased_key = block_device_mapping_aliases[block_device_mapping_key]
              instance_set = instance_set.reject{|instance| !instance['blockDeviceMapping'].find {|block_device_mapping| [*filter_value].include?(block_device_mapping[aliased_key])}}
            elsif instance_state_key = filter_key.split('instance-state-')[1]
              aliased_key = instance_state_aliases[instance_state_key]
              instance_set = instance_set.reject{|instance| ![*filter_value].include?(instance['instanceState'][aliased_key])}
            elsif state_reason_key = filter_key.split('state-reason-')[1]
              aliased_key = state_reason_aliases[state_reason_key]
              instance_set = instance_set.reject{|instance| ![*filter_value].include?(instance['stateReason'][aliased_key])}
            elsif filter_key == "availability-zone"
              aliased_key = aliases[filter_key]
              instance_set = instance_set.reject{|instance| ![*filter_value].include?(instance['placement'][aliased_key])}
            elsif filter_key == "group-name"
              instance_set = instance_set.reject {|instance| !instance['groupSet'].include?(filter_value)}
            elsif filter_key == "group-id"
              group_ids = [*filter_value]
              security_group_names = self.data[:security_groups].values.select { |sg| group_ids.include?(sg['groupId']) }.map { |sg| sg['groupName'] }
              instance_set = instance_set.reject {|instance| (security_group_names & instance['groupSet']).empty?}
            else
              aliased_key = aliases[filter_key]
              instance_set = instance_set.reject {|instance| ![*filter_value].include?(instance[aliased_key])}
            end
          end

          brand_new_instances = instance_set.select do |instance|
            instance['instanceState']['name'] == 'pending' &&
              Time.now - instance['launchTime'] < Fog::Mock.delay * 2
          end

          # Error if filtering for a brand new instance directly
          if (filters['instance-id'] || filters['instanceId']) && !brand_new_instances.empty?
            raise Fog::AWS::Compute::NotFound.new("The instance ID '#{brand_new_instances.first['instanceId']}' does not exist")
          end

          # Otherwise don't include it in the list
          instance_set = instance_set.reject {|instance| brand_new_instances.include?(instance) }

          response.status = 200
          reservation_set = {}

          instance_set.each do |instance|
            case instance['instanceState']['name']
            when 'pending'
              if Time.now - instance['launchTime'] >= Fog::Mock.delay * 2
                instance['ipAddress']         = Fog::AWS::Mock.ip_address
                instance['originalIpAddress'] = instance['ipAddress']
                instance['dnsName']           = Fog::AWS::Mock.dns_name_for(instance['ipAddress'])
                instance['instanceState']     = { 'code' => 16, 'name' => 'running' }
              end
            when 'rebooting'
              instance['instanceState'] = { 'code' => 16, 'name' => 'running' }
            when 'stopping'
              instance['instanceState'] = { 'code' => 0, 'name' => 'stopped' }
              instance['stateReason'] = { 'code' => 0 }
            when 'shutting-down'
              if Time.now - self.data[:deleted_at][instance['instanceId']] >= Fog::Mock.delay * 2
                self.data[:deleted_at].delete(instance['instanceId'])
                self.data[:instances].delete(instance['instanceId'])
              elsif Time.now - self.data[:deleted_at][instance['instanceId']] >= Fog::Mock.delay
                instance['instanceState'] = { 'code' => 48, 'name' => 'terminating' }
              end
            when 'terminating'
              if Time.now - self.data[:deleted_at][instance['instanceId']] >= Fog::Mock.delay
                self.data[:deleted_at].delete(instance['instanceId'])
                self.data[:instances].delete(instance['instanceId'])
              end
            end

            if self.data[:instances][instance['instanceId']]

              nics = self.data[:network_interfaces].select{|ni,ni_conf|
                ni_conf['attachment']['instanceId'] == instance['instanceId']
              }
              instance['networkInterfaces'] = nics.map{|ni,ni_conf|
                {
                  'ownerId' => ni_conf['ownerId'],
                  'subnetId' => ni_conf['subnetId'],
                  'vpcId' => ni_conf['vpcId'],
                  'networkInterfaceId' => ni_conf['networkInterfaceId'],
                  'groupSet' => ni_conf['groupSet'],
                  'attachmentId' => ni_conf['attachment']['attachmentId']
                }
              }
              if nics.count > 0

                instance['privateIpAddress'] = nics.sort_by {|ni, ni_conf|
                  ni_conf['attachment']['deviceIndex']
                }.map{ |ni, ni_conf| ni_conf['privateIpAddress'] }.first

                instance['privateDnsName'] = Fog::AWS::Mock.private_dns_name_for(instance['privateIpAddress'])
              else
                instance['privateIpAddress'] = ''
                instance['privateDnsName'] = ''
              end

              reservation_set[instance['reservationId']] ||= {
                'groupSet'      => instance['groupSet'],
                'groupIds'      => instance['groupIds'],
                'instancesSet'  => [],
                'ownerId'       => instance['ownerId'],
                'reservationId' => instance['reservationId']
              }
              reservation_set[instance['reservationId']]['instancesSet'] << instance.reject{|key,value| !['amiLaunchIndex', 'architecture', 'blockDeviceMapping', 'clientToken', 'dnsName', 'ebsOptimized', 'hypervisor', 'iamInstanceProfile', 'imageId', 'instanceId', 'instanceState', 'instanceType', 'ipAddress', 'kernelId', 'keyName', 'launchTime', 'monitoring', 'networkInterfaces', 'ownerId', 'placement', 'platform', 'privateDnsName', 'privateIpAddress', 'productCodes', 'ramdiskId', 'reason', 'rootDeviceName', 'rootDeviceType', 'spotInstanceRequestId', 'stateReason', 'subnetId', 'virtualizationType'].include?(key)}.merge('tagSet' => self.data[:tag_sets][instance['instanceId']])
            end
          end

          response.body = {
            'requestId'       => Fog::AWS::Mock.request_id,
            'reservationSet' => reservation_set.values
          }
          response
        end
      end
    end
  end
end
