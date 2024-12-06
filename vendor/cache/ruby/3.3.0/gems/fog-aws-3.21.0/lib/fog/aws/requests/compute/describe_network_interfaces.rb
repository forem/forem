module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_network_interfaces'

        # Describe all or specified network interfaces
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'networkInterfaceSet'<~Array>:
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
        # *     'instanceOwnerId'<~String>
        # *     'deviceIndex'<~Integer>
        # *     'status'<~String>
        # *     'attachTime'<~String>
        # *     'deleteOnTermination'<~Boolean>
        # *   'association'<~Hash>:         - Describes an eventual instance association
        # *     'attachmentID'<~String>     - ID of the network interface attachment
        # *     'instanceID'<~String>       - ID of the instance attached to the network interface
        # *     'publicIp'<~String>         - Address of the Elastic IP address bound to the network interface
        # *     'ipOwnerId'<~String>        - ID of the Elastic IP address owner
        # *   'tagSet'<~Array>:             - Tags assigned to the resource.
        # *     'key'<~String>              - Tag's key
        # *     'value'<~String>            - Tag's value
        # *   'privateIpAddresses' <~Array>:
        # *     'privateIpAddress'<~String> - One of the additional private ip address
        # *     'privateDnsName'<~String>   - The private DNS associate to the ip address
        # *     'primay'<~String>           - Whether main ip associate with NIC true of false
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2012-03-01/APIReference/index.html?ApiReference-query-DescribeNetworkInterfaces.html]
        def describe_network_interfaces(filters = {})
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action' => 'DescribeNetworkInterfaces',
            :idempotent => true,
            :parser => Fog::Parsers::AWS::Compute::DescribeNetworkInterfaces.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_network_interfaces(filters = {})
          response = Excon::Response.new

          network_interface_info = self.data[:network_interfaces].values

          if subnet_filter = filters.delete('subnet-id')
            filters['subnetId'] = subnet_filter
          end

          for filter_key, filter_value in filters
            network_interface_info = network_interface_info.reject{|nic| ![*filter_value].include?(nic[filter_key])}
          end

          response.status = 200
          response.body = {
            'requestId'           => Fog::AWS::Mock.request_id,
            'networkInterfaceSet' => network_interface_info
          }
          response
        end
      end
    end
  end
end
