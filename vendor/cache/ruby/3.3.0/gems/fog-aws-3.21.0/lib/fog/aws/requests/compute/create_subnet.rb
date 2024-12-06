module Fog
  module AWS
    class Compute
      class Real
        require 'ipaddr'
        require 'fog/aws/parsers/compute/create_subnet'

        # Creates a Subnet with the CIDR block you specify.
        #
        # ==== Parameters
        # * vpcId<~String> - The ID of the VPC where you want to create the subnet.
        # * cidrBlock<~String> - The CIDR block you want the Subnet to cover (e.g., 10.0.0.0/16).
        # * options<~Hash>:
        #   * AvailabilityZone<~String> - The Availability Zone you want the subnet in. Default: AWS selects a zone for you (recommended)
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'subnet'<~Array>:
        #   * 'subnetId'<~String> - The Subnet's ID
        #   * 'state'<~String> - The current state of the Subnet. ['pending', 'available']
        #   * 'cidrBlock'<~String> - The CIDR block the Subnet covers.
        #   * 'availableIpAddressCount'<~Integer> - The number of unused IP addresses in the subnet (the IP addresses for any stopped
        #     instances are considered unavailable)
        #   * 'availabilityZone'<~String> - The Availability Zone the subnet is in
        #   * 'tagSet'<~Array>: Tags assigned to the resource.
        #     * 'key'<~String> - Tag's key
        #     * 'value'<~String> - Tag's value
        #   * 'mapPublicIpOnLaunch'<~Boolean> - Indicates whether instances launched in this subnet receive a public IPv4 address.
        #   * 'defaultForAz'<~Boolean> - Indicates whether this is the default subnet for the Availability Zone.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2011-07-15/APIReference/ApiReference-query-CreateSubnet.html]
        def create_subnet(vpcId, cidrBlock, options = {})
          request({
            'Action'     => 'CreateSubnet',
            'VpcId'      => vpcId,
            'CidrBlock'  => cidrBlock,
            :parser      => Fog::Parsers::AWS::Compute::CreateSubnet.new
          }.merge!(options))
        end
      end

      class Mock
        def create_subnet(vpcId, cidrBlock, options = {})
          av_zone = options['AvailabilityZone'].nil? ? 'us-east-1c' : options['AvailabilityZone']
          Excon::Response.new.tap do |response|
            if cidrBlock && vpcId
              vpc = self.data[:vpcs].find{ |v| v['vpcId'] == vpcId }
              if vpc.nil?
                raise Fog::AWS::Compute::NotFound.new("The vpc ID '#{vpcId}' does not exist")
              end
              if ! ::IPAddr.new(vpc['cidrBlock']).include?(::IPAddr.new(cidrBlock))
                raise Fog::AWS::Compute::Error.new("Range => The CIDR '#{cidrBlock}' is invalid.")
              end
              self.data[:subnets].select{ |s| s['vpcId'] == vpcId }.each do |subnet|
                if ::IPAddr.new(subnet['cidrBlock']).include?(::IPAddr.new(cidrBlock))
                  raise Fog::AWS::Compute::Error.new("Conflict => The CIDR '#{cidrBlock}' conflicts with another subnet")
                end
              end

              response.status = 200
              data = {
                'subnetId'                 => Fog::AWS::Mock.subnet_id,
                'state'                    => 'pending',
                'vpcId'                    => vpcId,
                'cidrBlock'                => cidrBlock,
                'availableIpAddressCount'  => "255",
                'availabilityZone'         => av_zone,
                'tagSet'                   => {},
                'mapPublicIpOnLaunch'      => true,
                'defaultForAz'             => true
              }

              # Add this subnet to the default network ACL
              accid = Fog::AWS::Mock.network_acl_association_id
              default_nacl = self.data[:network_acls].values.find { |nacl| nacl['vpcId'] == vpcId && nacl['default'] }
              default_nacl['associationSet'] << {
                'networkAclAssociationId' => accid,
                'networkAclId'            => default_nacl['networkAclId'],
                'subnetId'                => data['subnetId'],
              }

              self.data[:subnets].push(data)
              response.body = {
                'requestId'    => Fog::AWS::Mock.request_id,
                'subnet'       => data,
              }
            else
              response.status = 400
              response.body = {
                'Code' => 'InvalidParameterValue'
              }
              if cidrBlock.empty?
                response.body['Message'] = "Invalid value '' for cidrBlock. Must be specified."
              end
              if vpcId.empty?
                response.body['Message'] = "Invalid value '' for vpcId. Must be specified."
              end
            end
          end
        end
      end
    end
  end
end
