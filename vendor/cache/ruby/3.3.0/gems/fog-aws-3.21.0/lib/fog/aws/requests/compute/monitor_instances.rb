module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/monitor_unmonitor_instances'

        # Monitor specified instance
        # http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-MonitorInstances.html
        #
        # ==== Parameters
        # * instance_ids<~Array> - Arrays of instances Ids to monitor
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'instancesSet': http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-ItemType-MonitorInstancesResponseSetItemType.html
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-MonitorInstances.html]
        def monitor_instances(instance_ids)
          params = Fog::AWS.indexed_param('InstanceId', instance_ids)
          request({
                          'Action' => 'MonitorInstances',
                          :idempotent => true,
                          :parser => Fog::Parsers::AWS::Compute::MonitorUnmonitorInstances.new
                  }.merge!(params))
        end
      end

      class Mock
        def monitor_instances(instance_ids)
          response        = Excon::Response.new
          response.status = 200
          [*instance_ids].each do |instance_id|
            if instance = self.data[:instances][instance_id]
              instance['monitoring']['state'] = 'enabled'
            else
              raise Fog::AWS::Compute::NotFound.new("The instance ID '#{instance_ids}' does not exist")
            end
          end
          instances_set = [*instance_ids].reduce([]) { |memo, id| memo << {'instanceId' => id, 'monitoring' => 'enabled'} }
          response.body = {'requestId' => 'some_request_id', 'instancesSet' => instances_set}
          response
        end
      end
    end
  end
end
