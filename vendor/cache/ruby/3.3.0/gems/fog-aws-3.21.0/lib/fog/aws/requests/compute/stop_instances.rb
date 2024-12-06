module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/start_stop_instances'

        # Stop specified instance
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
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-StopInstances.html]
        def stop_instances(instance_id, options = {})
          params = Fog::AWS.indexed_param('InstanceId', instance_id)
          unless options.is_a?(Hash)
            Fog::Logger.warning("stop_instances with #{options.class} param is deprecated, use stop_instances('force' => boolean) instead [light_black](#{caller.first})[/]")
            options = {'force' => options}
          end
          params.merge!('Force' => 'true') if options['force']
          if options['hibernate']
            params.merge!('Hibernate' => 'true')
            params.merge!('Force' => 'false')
          end
          request({
            'Action'    => 'StopInstances',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::StartStopInstances.new
          }.merge!(params))
        end
      end

      class Mock
        def stop_instances(instance_id, options = {})
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
                                  instance['classicLinkSecurityGroups'] = nil
                                  instance['classicLinkVpcId'] = nil
                                  ia << {'currentState' => { 'code' => 0, 'name' => 'stopping' },
                                         'previousState' => instance['instanceState'],
                                         'instanceId' => instance['instanceId'] }
                                  instance['instanceState'] = {'code'=>0, 'name'=>'stopping'}
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
