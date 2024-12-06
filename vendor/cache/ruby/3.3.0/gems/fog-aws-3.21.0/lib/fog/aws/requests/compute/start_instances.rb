module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/start_stop_instances'

        # Start specified instance
        #
        # ==== Parameters
        # * instance_id<~Array> - Id of instance to start
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * TODO: fill in the blanks
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-StartInstances.html]
        def start_instances(instance_id)
          params = Fog::AWS.indexed_param('InstanceId', instance_id)
          request({
            'Action'    => 'StartInstances',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::StartStopInstances.new
          }.merge!(params))
        end
      end

      class Mock
        def start_instances(instance_id)
          instance_ids = Array(instance_id)

          instance_set = self.data[:instances].values
          instance_set = apply_tag_filters(instance_set, {'instance_id' => instance_ids}, 'instanceId')
          instance_set = instance_set.select {|x| instance_ids.include?(x["instanceId"]) }

          if instance_set.empty?
            raise Fog::AWS::Compute::NotFound.new("The instance ID '#{instance_ids.first}' does not exist")
          else
            response = Excon::Response.new
            response.status = 200

            response.body = {
              'requestId'    => Fog::AWS::Mock.request_id,
              'instancesSet' => instance_set.reduce([]) do |ia, instance|
                                  ia << {'currentState' => { 'code' => 0, 'name' => 'pending' },
                                         'previousState' => instance['instanceState'],
                                         'instanceId' => instance['instanceId'] }
                                  instance['instanceState'] = {'code'=>0, 'name'=>'pending'}
                                  ia
              end
            }
            response
          end
        end
      end
    end
  end
end
