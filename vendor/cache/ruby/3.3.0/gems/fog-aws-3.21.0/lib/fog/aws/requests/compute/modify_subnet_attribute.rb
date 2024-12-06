module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/modify_subnet_attribute'

        # Modifies a subnet attribute.
        #
        # ==== Parameters
        # * SubnetId<~String> - The id of the subnet to modify
        # * options<~Hash>:
        #   * MapPublicIpOnLaunch<~Boolean> - Modifies the public IP addressing behavior for the subnet. 
        #     Specify true to indicate that instances launched into the specified subnet should be assigned a public IP address. 
        #     If set to true, the instance receives a public IP address only if the instance is launched with a single, 
        #     new network interface with the device index of 0.
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'return'<~Boolean> - Returns true if the request succeeds. Otherwise, returns an error.
        # http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-ModifySubnetAttribute.html
        def modify_subnet_attribute(subnet_id, options = {})
          params = {}
          params['MapPublicIpOnLaunch.Value'] = options.delete 'MapPublicIpOnLaunch' if options['MapPublicIpOnLaunch']
          request({
            'Action' => 'ModifySubnetAttribute',
            'SubnetId' => subnet_id,
            :parser => Fog::Parsers::AWS::Compute::ModifySubnetAttribute.new
          }.merge(params))
        end
      end

      class Mock
        def modify_subnet_attribute(subnet_id, options={})
          Excon::Response.new.tap do |response|
            subnet = self.data[:subnets].detect { |v| v['subnetId'] == subnet_id }            
            if subnet
              subnet['mapPublicIpOnLaunch'] = options['MapPublicIpOnLaunch']

              response.status = 200
              
              response.body = {
                'requestId' => Fog::AWS::Mock.request_id,
                'return'    => true
              }
            else
              response.status = 404
              response.body = {
                'Code' => 'InvalidParameterValue'
              }
            end
          end
        end
      end
    end
  end
end
