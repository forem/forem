module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/create_network_acl'

        # Creates a network ACL
        #
        # ==== Parameters
        # * vpcId<~String> - The ID of the VPC to create this network ACL under
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>                   - Id of request
        # * 'networkAcl'<~Array>:                  - The network ACL
        # *   'networkAclId'<~String>              - The ID of the network ACL
        # *   'vpcId'<~String>                     - The ID of the VPC for the network ACL
        # *   'default'<~Boolean>                  - Indicates whether this is the default network ACL for the VPC
        # *   'entrySet'<~Array>:                  - A list of entries (rules) in the network ACL
        # *     'ruleNumber'<~Integer>             - The rule number for the entry. ACL entries are processed in ascending order by rule number
        # *     'protocol'<~Integer>               - The protocol. A value of -1 means all protocols
        # *     'ruleAction'<~String>              - Indicates whether to allow or deny the traffic that matches the rule
        # *     'egress'<~Boolean>                 - Indicates whether the rule is an egress rule (applied to traffic leaving the subnet)
        # *     'cidrBlock'<~String>               - The network range to allow or deny, in CIDR notation
        # *     'icmpTypeCode'<~Hash>              - ICMP protocol: The ICMP type and code
        # *       'code'<~Integer>                 - The ICMP code. A value of -1 means all codes for the specified ICMP type
        # *       'type'<~Integer>                 - The ICMP type. A value of -1 means all types
        # *     'portRange'<~Hash>                 - TCP or UDP protocols: The range of ports the rule applies to
        # *       'from'<~Integer>                 - The first port in the range
        # *       'to'<~Integer>                   - The last port in the range
        # *   'associationSet'<~Array>:            - A list of associations between the network ACL and subnets
        # *     'networkAclAssociationId'<~String> - The ID of the association
        # *     'networkAclId'<~String>            - The ID of the network ACL
        # *     'subnetId'<~String>                - The ID of the subnet
        # *   'tagSet'<~Array>:                    - Tags assigned to the resource.
        # *     'key'<~String>                     - Tag's key
        # *     'value'<~String>                   - Tag's value
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-CreateNetworkAcl.html]
        def create_network_acl(vpcId, options = {})
          request({
            'Action' => 'CreateNetworkAcl',
            'VpcId'  => vpcId,
            :parser  => Fog::Parsers::AWS::Compute::CreateNetworkAcl.new
          }.merge!(options))
        end
      end

      class Mock
        def create_network_acl(vpcId, options = {})
          response = Excon::Response.new
          if vpcId
            id = Fog::AWS::Mock.network_acl_id

            unless self.data[:vpcs].find { |s| s['vpcId'] == vpcId }
              raise Fog::AWS::Compute::Error.new("Unknown VPC '#{vpcId}' specified")
            end

            data = {
              'networkAclId'   => id,
              'vpcId'          => vpcId,
              'default'        => false,
              'entrySet'       => [
                {
                  'icmpTypeCode' => {},
                  'portRange'    => {},
                  'ruleNumber'   => 32767,
                  'protocol'     => -1,
                  'ruleAction'   => "deny",
                  'egress'       => true,
                  'cidrBlock'    => "0.0.0.0/0",
                },
                {
                  'icmpTypeCode' => {},
                  'portRange'    => {},
                  'ruleNumber'   => 32767,
                  'protocol'     => -1,
                  'ruleAction'   => "deny",
                  'egress'       => false,
                  'cidrBlock'    => "0.0.0.0/0",
                },
              ],
              'associationSet' => [],
              'tagSet'         => {}
            }

            self.data[:network_acls][id] = data
            response.body = {
              'requestId'  => Fog::AWS::Mock.request_id,
              'networkAcl' => data
            }
          else
            response.status = 400
            response.body = {
              'Code'    => 'InvalidParameterValue',
              'Message' => "Invalid value '' for subnetId"
            }
          end
          response
        end
      end
    end
  end
end
