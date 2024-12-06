module Fog
  module AWS
    class Compute
      class Real
        require 'ipaddr'
        require 'fog/aws/parsers/compute/create_network_interface'

        # Creates a network interface
        #
        # ==== Parameters
        # * subnetId<~String> - The ID of the subnet to associate with the network interface
        # * options<~Hash>:
        #   * PrivateIpAddress<~String> - The private IP address of the network interface
        #   * Description<~String>      - The description of the network interface
        #   * GroupSet<~Array>          - The security group IDs for use by the network interface
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>          - Id of request
        # * 'networkInterface'<~Hash>     - The created network interface
        # *   'networkInterfaceId'<~String> - The ID of the network interface
        # *   'subnetId'<~String>           - The ID of the subnet
        # *   'vpcId'<~String>              - The ID of the VPC
        # *   'availabilityZone'<~String>   - The availability zone
        # *   'description'<~String>        - The description
        # *   'ownerId'<~String>            - The ID of the person who created the interface
        # *   'requesterId'<~String>        - The ID ot teh entity requesting this interface
        # *   'requesterManaged'<~String>   -
        # *   'status'<~String>             - "available" or "in-use"
        # *   'macAddress'<~String>         -
        # *   'privateIpAddress'<~String>   - IP address of the interface within the subnet
        # *   'privateDnsName'<~String>     - The private DNS name
        # *   'sourceDestCheck'<~Boolean>   - Flag indicating whether traffic to or from the instance is validated
        # *   'groupSet'<~Hash>             - Associated security groups
        # *     'key'<~String>              - ID of associated group
        # *     'value'<~String>            - Name of associated group
        # *   'attachment'<~Hash>:          - Describes the way this nic is attached
        # *     'attachmentID'<~String>
        # *     'instanceID'<~String>
        # *   'association'<~Hash>:         - Describes an eventual instance association
        # *     'attachmentID'<~String>     - ID of the network interface attachment
        # *     'instanceID'<~String>       - ID of the instance attached to the network interface
        # *     'publicIp'<~String>         - Address of the Elastic IP address bound to the network interface
        # *     'ipOwnerId'<~String>        - ID of the Elastic IP address owner
        # *   'tagSet'<~Array>:             - Tags assigned to the resource.
        # *     'key'<~String>              - Tag's key
        # *     'value'<~String>            - Tag's value
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2012-03-01/APIReference/ApiReference-query-CreateNetworkInterface.html]
        def create_network_interface(subnetId, options = {})
          if security_groups = options.delete('GroupSet')
            options.merge!(Fog::AWS.indexed_param('SecurityGroupId', [*security_groups]))
          end
          request({
            'Action'     => 'CreateNetworkInterface',
            'SubnetId'   => subnetId,
            :parser      => Fog::Parsers::AWS::Compute::CreateNetworkInterface.new
          }.merge!(options))
        end
      end

      class Mock
        def create_network_interface(subnetId, options = {})
          response = Excon::Response.new
          if subnetId
            subnet = self.data[:subnets].find{ |s| s['subnetId'] == subnetId }
            if subnet.nil?
              raise Fog::AWS::Compute::Error.new("Unknown subnet '#{subnetId}' specified")
            else
              id = Fog::AWS::Mock.network_interface_id
              cidr_block = IPAddr.new(subnet['cidrBlock'])

              groups = {}
              if options['GroupSet']
                options['GroupSet'].each do |group_id|
                  group_obj = self.data[:security_groups][group_id]
                  if group_obj.nil?
                    raise Fog::AWS::Compute::Error.new("Unknown security group '#{group_id}' specified")
                  end
                  groups[group_id] = group_obj['groupName']
                end
              end

              if options['PrivateIpAddress'].nil?
                range = cidr_block.to_range
                # Here we try to act like a DHCP server and pick the first
                # available IP (not including the first in the cidr block,
                # which is typically reserved for the gateway).
                range = range.drop(2)[0..-2] if cidr_block.ipv4?

                range.each do |p_ip|
                  unless self.data[:network_interfaces].map{ |ni, ni_conf| ni_conf['privateIpAddress'] }.include?p_ip.to_s
                    options['PrivateIpAddress'] = p_ip.to_s
                    break
                  end
                end
              elsif self.data[:network_interfaces].map{ |ni,ni_conf| ni_conf['privateIpAddress'] }.include?options['PrivateIpAddress']
                raise Fog::AWS::Compute::Error.new('InUse => The specified address is already in use.')
              end

              data = {
                'networkInterfaceId' => id,
                'subnetId'           => subnetId,
                'vpcId'              => 'mock-vpc-id',
                'availabilityZone'   => 'mock-zone',
                'description'        => options['Description'],
                'ownerId'            => '',
                'requesterManaged'   => 'false',
                'status'             => 'available',
                'macAddress'         => '00:11:22:33:44:55',
                'privateIpAddress'   => options['PrivateIpAddress'],
                'sourceDestCheck'    => true,
                'groupSet'           => groups,
                'attachment'         => {},
                'association'        => {},
                'tagSet'             => {}
              }
              self.data[:network_interfaces][id] = data
              response.body = {
                'requestId'        => Fog::AWS::Mock.request_id,
                'networkInterface' => data
              }
              response
            end
          else
            response.status = 400
            response.body = {
              'Code'    => 'InvalidParameterValue',
              'Message' => "Invalid value '' for subnetId"
            }
          end
        end
      end
    end
  end
end
