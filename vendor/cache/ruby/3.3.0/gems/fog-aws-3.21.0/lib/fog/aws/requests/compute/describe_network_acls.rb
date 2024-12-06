module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_network_acls'

        # Describe all or specified network ACLs
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>                   - Id of request
        # * 'networkAclSet'<~Array>:               - A list of network ACLs
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
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeNetworkAcls.html]
        def describe_network_acls(filters = {})
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action' => 'DescribeNetworkAcls',
            :idempotent => true,
            :parser => Fog::Parsers::AWS::Compute::DescribeNetworkAcls.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_network_acls(filters = {})
          response = Excon::Response.new

          network_acls = self.data[:network_acls].values
          network_acls = apply_tag_filters(network_acls, filters, 'networkAclId')

          aliases = {
            'vpc-id'         => 'vpcId',
            'network-acl-id' => 'networkAclId',
            'default'        => 'default',
          }
          association_aliases = {
            'association-id' => 'networkAclAssociationId',
            'network-acl-id' => 'networkAclId',
            'subnet-id'      => 'subnetId',
          }
          entry_aliases = {
            'cidr'        => 'cidrBlock',
            'egress'      => 'egress',
            'rule-action' => 'ruleAction',
            'rule-number' => 'ruleNumber',
            'protocol'    => 'protocol'
          }
          for filter_key, filter_value in filters
            filter_key = filter_key.to_s
            if association_key = filter_key.split('association.')[1]
              aliased_key = association_aliases[association_key]
              network_acls = network_acls.reject{|nacl| !nacl['associationSet'].find {|association| [*filter_value].include?(association[aliased_key])}}
            elsif entry_key = filter_key.split('entry.icmp.')[1]
              network_acls = network_acls.reject{|nacl| !nacl['entrySet'].find {|association| [*filter_value].include?(association['icmpTypeCode'][entry_key])}}
            elsif entry_key = filter_key.split('entry.port-range.')[1]
              network_acls = network_acls.reject{|nacl| !nacl['entrySet'].find {|association| [*filter_value].include?(association['portRange'][entry_key])}}
            elsif entry_key = filter_key.split('entry.')[1]
              aliased_key = entry_aliases[entry_key]
              network_acls = network_acls.reject{|nacl| !nacl['entrySet'].find {|association| [*filter_value].include?(association[aliased_key])}}
            else
              aliased_key = aliases[filter_key]
              network_acls = network_acls.reject{|nacl| ![*filter_value].include?(nacl[aliased_key])}
            end
          end

          network_acls.each do |acl|
            tags = self.data[:tag_sets][acl['networkAclId']]
            acl.merge!('tagSet' => tags) if tags
          end

          response.status = 200
          response.body = {
            'requestId'     => Fog::AWS::Mock.request_id,
            'networkAclSet' => network_acls
          }
          response
        end
      end
    end
  end
end
