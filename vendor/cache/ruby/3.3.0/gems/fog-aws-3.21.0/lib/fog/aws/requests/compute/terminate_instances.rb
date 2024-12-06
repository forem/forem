module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/terminate_instances'

        # Terminate specified instances
        #
        # ==== Parameters
        # * instance_id<~Array> - Ids of instances to terminates
        #
        # ==== Returns
        # # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'instancesSet'<~Array>:
        #       * 'instanceId'<~String> - id of the terminated instance
        #       * 'previousState'<~Hash>: previous state of instance
        #         * 'code'<~Integer> - previous status code
        #         * 'name'<~String> - name of previous state
        #       * 'shutdownState'<~Hash>: shutdown state of instance
        #         * 'code'<~Integer> - current status code
        #         * 'name'<~String> - name of current state
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-TerminateInstances.html]
        def terminate_instances(instance_id)
          params = Fog::AWS.indexed_param('InstanceId', instance_id)
          request({
            'Action'    => 'TerminateInstances',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::TerminateInstances.new
          }.merge!(params))
        end
      end

      class Mock
        def terminate_instances(instance_id)
          response = Excon::Response.new
          instance_id = [*instance_id]
          if (self.data[:instances].keys & instance_id).length == instance_id.length
            response.body = {
              'requestId'     => Fog::AWS::Mock.request_id,
              'instancesSet'  => []
            }
            response.status = 200
            for id in instance_id
              instance = self.data[:instances][id]
              instance['classicLinkSecurityGroups'] = nil
              instance['classicLinkVpcId'] = nil
              self.data[:deleted_at][id] = Time.now
              code = case instance['instanceState']['name']
              when 'pending'
                0
              when 'running'
                16
              when 'shutting-down'
                32
              when 'terminated'
                48
              when 'stopping'
                64
              when 'stopped'
                80
              end
              state = { 'name' => 'shutting-down', 'code' => 32}
              response.body['instancesSet'] << {
                'instanceId'    => id,
                'previousState' => instance['instanceState'],
                'currentState'  => state
              }
              instance['instanceState'] = state
            end

            describe_addresses.body['addressesSet'].each do |address|
              if instance_id.include?(address['instanceId'])
                disassociate_address(address['publicIp'], address['associationId'])
              end
            end

            describe_volumes.body['volumeSet'].each do |volume|
              if volume['attachmentSet'].first && instance_id.include?(volume['attachmentSet'].first['instanceId'])
                detach_volume(volume['volumeId'])
              end
            end

            response
          else
            raise Fog::AWS::Compute::NotFound.new("The instance ID '#{instance_id}' does not exist")
          end
        end
      end
    end
  end
end
